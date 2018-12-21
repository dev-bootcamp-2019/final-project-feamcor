pragma solidity 0.5.2;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/drafts/Counter.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/utils/Address.sol";

/// @author Fábio Corrêa <feamcor@gmail.com>
/// @title A simple decentralized ticket store on Ethereum
contract Bileto is Ownable {
    enum StoreStatus {
        Created,
        Open,
        Suspended,
        Closed
    }

    enum EventStatus {
        Created,
        SalesStarted,
        SalesSuspended,
        SalesEnded,
        Settled,
        Cancelled
    }

    enum PurchaseStatus {
        Completed,
        Cancelled,
        Refunded,
        CheckedIn
    }

    struct Event {
        EventStatus status;
        bytes32 externalId;
        address organizer;
        string name;
        uint storeIncentive;
        uint ticketPrice;
        uint ticketsOnSale;
        uint ticketsSold;
        uint ticketsCancelled;
        uint ticketsRefunded;
        uint ticketsCheckedIn;
        uint eventBalance;
        uint storeBalance;
    }

    struct Purchase {
        PurchaseStatus status;
        bytes32 externalId;
        uint externalTimestamp;
        address buyer;
        bytes32 buyerId;
        uint quantity;
        uint total;
        uint eventId;
    }

    uint constant private TIME_WINDOW = 15 * 60;
    
    StoreStatus public storeStatus;
    
    Counter.Counter public eventsCounter;
    mapping(uint => Event) public events;

    Counter.Counter public purchasesCounter;
    mapping(uint => Purchase) public purchases;

    event StoreCreated(address indexed _by);
    event StoreOpen(address indexed _by);
    event StoreSuspended(address indexed _by);
    event StoreClosed(address indexed _by);

    event EventCreated(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventSalesStarted(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventSalesSuspended(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventSalesEnded(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventSettled(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    event PurchaseCompleted(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);
    event PurchaseCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);
    event PurchaseRefunded(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);
    event CustomerCheckedIn(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);

    modifier storeNotClosed() {
        require(storeStatus != StoreStatus.Closed, "store cannot be closed");
        _;
    }

    modifier storeOpen() {
        require(storeStatus == StoreStatus.Open, "store must be open");
        _;
    }

    modifier storeSuspended() {
        require(storeStatus == StoreStatus.Suspended, "store must be suspended");
        _;
    }

    modifier onlyOrganizer(uint _eventId) {
        require(_eventId <= eventsCounter.current && msg.sender == events[_eventId].organizer,
            "must be organizer to proceed (or invalid event)");
        _; 
    }

    modifier validEvent(uint _eventId) {
        require(_eventId <= eventsCounter.current, "event must be valid");
        _;
    }

    modifier eventNotCancelled(uint _eventId) {
        require(_eventId <= eventsCounter.current && events[_eventId].status != EventStatus.Cancelled,
            "event cannot be cancelled (or invalid event)");
        _;
    }

    modifier eventOnSale(uint _eventId) {
        require(_eventId <= eventsCounter.current && events[_eventId].status == EventStatus.SalesStarted,
            "ticket sales must be started (or invalid event)");
        _;
    }

    modifier purchaseCompleted(uint _purchaseId) {
        require(_purchaseId <= purchasesCounter.current && purchases[_purchaseId].status == PurchaseStatus.Completed,
            "purchase must be completed (or invalid purchase)");
        _;
    }

    modifier eventOrPurchaseCancelled(uint _eventId, uint _purchaseId) {
        require(_eventId <= eventsCounter.current &&
            _purchaseId <= purchasesCounter.current &&
            (events[_eventId].status == EventStatus.Cancelled ||
            purchases[_purchaseId].status == PurchaseStatus.Cancelled),
            "event or purchase must be cancelled (or invalid event/purchase)");
        _;
    }

    /// @notice Create a store with its respective owner.
    /// @dev store owner is set by the account who created the store
    constructor() public {
        storeStatus = StoreStatus.Created;
        emit StoreCreated(owner());
    }

    function() external payable {
        require(msg.data.length == 0, "only funds transfer accepted");
    }

    function openStore() external onlyOwner storeNotClosed {
        storeStatus = StoreStatus.Open;
        emit StoreOpen(owner());
    } 

    function suspendStore() external onlyOwner storeOpen {
        storeStatus = StoreStatus.Suspended;
        emit StoreSuspended(owner());
    }

    function closeStore() external onlyOwner storeNotClosed {
        storeStatus = StoreStatus.Closed;
        emit StoreClosed(owner());
    }

    function createEvent(
        string calldata _externalId,
        address _organizer,
        string calldata _name,
        uint _storeIncentive,
        uint _ticketPrice,
        uint _ticketsOnSale
    )
        external
        onlyOwner
        storeOpen
        returns (uint _eventId)
    {
        require(!Address.isContract(_organizer), "a contract cannot be the organizer of an event");
        require(bytes(_externalId).length != 0, "event external ID must not be empty");
        require(bytes(_name).length != 0, "event name must not be empty");
        require(_storeIncentive >= 0 && _storeIncentive <= 10000, "invalid store incentive");
        require(_ticketsOnSale > 0, "number of tickets on sale cannot be zero");
        _eventId = Counter.next(eventsCounter);
        events[_eventId].status = EventStatus.Created;
        events[_eventId].externalId = keccak256(bytes(_externalId));
        events[_eventId].organizer = _organizer;
        events[_eventId].name = _name;
        events[_eventId].storeIncentive = _storeIncentive;
        events[_eventId].ticketPrice = _ticketPrice;
        events[_eventId].ticketsOnSale = _ticketsOnSale;
        emit EventCreated(_eventId, events[_eventId].externalId, msg.sender);
    }

    function startTicketSales(uint _eventId)
        external
        storeOpen
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "cannot start ticket sale for this event");
        events[_eventId].status = EventStatus.SalesStarted;
        emit EventSalesStarted(_eventId, events[_eventId].externalId, msg.sender);
    }

    function suspendTicketSales(uint _eventId)
        external
        storeOpen
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted,
            "cannot suspend ticket sale for this event");
        events[_eventId].status = EventStatus.SalesSuspended;
        emit EventSalesSuspended(_eventId, events[_eventId].externalId, msg.sender);
    }

    function endTicketSales(uint _eventId)
        external
        storeOpen
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "cannot end ticket sale for this event");
        events[_eventId].status = EventStatus.SalesEnded;
        emit EventSalesEnded(_eventId, events[_eventId].externalId, msg.sender);
    }

    function cancelEvent(uint _eventId)
        external
        storeOpen
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        events[_eventId].status = EventStatus.Cancelled;
        emit EventCancelled(_eventId, events[_eventId].externalId, msg.sender);
    }

    function purchaseTickets(
        uint _eventId,
        uint _quantity,
        string calldata _externalId,
        uint _timestamp,
        string calldata _buyerId
    )
        external
        payable
        storeOpen
        eventOnSale(_eventId)
        returns (uint _purchaseId)
    {
        require(!Address.isContract(msg.sender), "a contract cannot purchase tickets");
        require(_quantity > 0, "quantity must be greater than zero");
        require(bytes(_externalId).length != 0, "purchase external ID must not be empty");
        require(_timestamp >= now - TIME_WINDOW && _timestamp <= now + TIME_WINDOW, "invalid purchase timestamp");
        require(bytes(_buyerId).length != 0, "buyer ID must not be empty");
        require(msg.value == SafeMath.mul(_quantity, events[_eventId].ticketPrice), "funds not equal to total");
        _purchaseId = Counter.next(purchasesCounter);
        purchases[_purchaseId].status = PurchaseStatus.Completed;
        purchases[_purchaseId].externalId = keccak256(bytes(_externalId));
        purchases[_purchaseId].externalTimestamp = _timestamp;
        purchases[_purchaseId].buyer = msg.sender;
        purchases[_purchaseId].buyerId = keccak256(bytes(_buyerId));
        purchases[_purchaseId].quantity = _quantity;
        purchases[_purchaseId].total = SafeMath.mul(_quantity, events[_eventId].ticketPrice);
        purchases[_purchaseId].eventId = _eventId;
        events[_eventId].eventBalance = SafeMath.add(events[_eventId].eventBalance, purchases[_purchaseId].total);
        emit PurchaseCompleted(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    function cancelPurchase(
        uint _eventId,
        uint _purchaseId,
        string calldata _buyerId,
        string calldata _externalId
    )
        external
        storeOpen
        eventNotCancelled(_eventId)
        purchaseCompleted(_purchaseId)
    {
        require(msg.sender == purchases[_purchaseId].buyer, "only buyer can cancel purchase");
        require(keccak256(bytes(_buyerId)) == purchases[_purchaseId].buyerId, "invalid buyer ID");
        require(keccak256(bytes(_externalId)) == purchases[_purchaseId].externalId, "invalid purchase external ID");
        purchases[_purchaseId].status = PurchaseStatus.Cancelled;
        events[_eventId].eventBalance = SafeMath.sub(events[_eventId].eventBalance, purchases[_purchaseId].total);
        emit PurchaseCancelled(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    function refundPurchase(
        uint _eventId,
        uint _purchaseId,
        string calldata _buyerId,
        string calldata _externalId
    )
        external
        storeOpen
        eventOrPurchaseCancelled(_eventId, _purchaseId)
    {
        require(msg.sender == purchases[_purchaseId].buyer, "only buyer can request refund");
        require(keccak256(bytes(_buyerId)) == purchases[_purchaseId].buyerId, "invalid buyer ID");
        require(keccak256(bytes(_externalId)) == purchases[_purchaseId].externalId, "invalid purchase external ID");
        purchases[_purchaseId].status = PurchaseStatus.Refunded;
        emit PurchaseRefunded(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }
}
