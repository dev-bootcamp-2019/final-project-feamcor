pragma solidity 0.5.2;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/drafts/Counter.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/utils/Address.sol";
import "../node_modules/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

/// @author Fábio Corrêa <feamcor@gmail.com>
/// @title A simple decentralized ticket store on Ethereum
contract Bileto is Ownable, ReentrancyGuard {
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
        SalesFinished,
        Completed,
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
        uint ticketsLeft;
        uint ticketsCancelled;
        uint ticketsRefunded;
        uint ticketsCheckedIn;
        uint eventBalance;
        uint refundableBalance;
    }

    struct Purchase {
        PurchaseStatus status;
        bytes32 externalId;
        uint timestamp;
        address customer;
        bytes32 customerId;
        uint quantity;
        uint total;
        uint eventId;
    }

    uint constant private TIME_WINDOW = 15 * 60;

    StoreStatus public storeStatus;
    uint public storeRefundableBalance;

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
    event EventSalesFinished(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventCompleted(uint indexed _id, bytes32 indexed _extId, address indexed _by);
    event EventSettled(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _settlement);
    event EventCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    event PurchaseCompleted(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);
    event PurchaseCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);
    event PurchaseRefunded(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);

    event CustomerCheckedIn(uint indexed _event_id, uint indexed _purchaseId, address indexed _by);

    modifier storeOpen() {
        require(storeStatus == StoreStatus.Open, "store must be open");
        _;
    }

    modifier onlyOrganizer(uint _eventId) {
        require(_eventId <= eventsCounter.current &&
            msg.sender == events[_eventId].organizer,
            "must be organizer to proceed (or invalid event)");
        _;
    }

    modifier eventOnSale(uint _eventId) {
        require(_eventId <= eventsCounter.current &&
            events[_eventId].status == EventStatus.SalesStarted,
            "ticket sales must be started (or invalid event)");
        _;
    }

    modifier purchaseCompleted(uint _purchaseId) {
        require(_purchaseId <= purchasesCounter.current &&
            purchases[_purchaseId].status == PurchaseStatus.Completed,
            "purchase must be completed (or invalid purchase)");
        _;
    }

    modifier purchaseCancelled(uint _purchaseId) {
        require(_purchaseId <= purchasesCounter.current &&
            purchases[_purchaseId].status == PurchaseStatus.Cancelled,
            "purchase must be cancelled (or invalid purchase)");
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

    function openStore() external nonReentrant onlyOwner {
        require(storeStatus == StoreStatus.Created ||
            storeStatus == StoreStatus.Suspended,
            "store cannot be opened");
        storeStatus = StoreStatus.Open;
        emit StoreOpen(owner());
    }

    function suspendStore() external nonReentrant onlyOwner storeOpen {
        storeStatus = StoreStatus.Suspended;
        emit StoreSuspended(owner());
    }

    function closeStore() external nonReentrant onlyOwner {
        require(storeStatus != StoreStatus.Closed, "store cannot be closed");
        require(storeRefundableBalance == 0, "store has refundable balance");
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
        nonReentrant
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
        events[_eventId].ticketsLeft = _ticketsOnSale;
        emit EventCreated(_eventId, events[_eventId].externalId, msg.sender);
    }

    function startTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "cannot start ticket sale for this event");
        events[_eventId].status = EventStatus.SalesStarted;
        emit EventSalesStarted(_eventId, events[_eventId].externalId, msg.sender);
    }

    function suspendTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted,
            "cannot suspend ticket sale for this event");
        events[_eventId].status = EventStatus.SalesSuspended;
        emit EventSalesSuspended(_eventId, events[_eventId].externalId, msg.sender);
    }

    function endTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "cannot end ticket sale for this event");
        events[_eventId].status = EventStatus.SalesFinished;
        emit EventSalesFinished(_eventId, events[_eventId].externalId, msg.sender);
    }

    function completeEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesFinished, "cannot complete event");
        events[_eventId].status = EventStatus.Completed;
        emit EventCompleted(_eventId, events[_eventId].externalId, msg.sender);
    }

    function settleEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOwner
    {
        require(events[_eventId].status == EventStatus.Completed, "cannot settle event");
        events[_eventId].status = EventStatus.Settled;
        uint _eventBalance = events[_eventId].eventBalance;
        uint _storeIncentive = events[_eventId].storeIncentive;
        uint _storeBalance = SafeMath.div(SafeMath.mul(_eventBalance, _storeIncentive), 10000);
        uint _settlement = SafeMath.sub(_eventBalance, _storeBalance);
        // TO-DO: transfer settlement to organizer account
        emit EventSettled(_eventId, events[_eventId].externalId, msg.sender, _settlement);
    }

    function cancelEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.SalesFinished,
            "cannot cancel event");
        events[_eventId].status = EventStatus.Cancelled;
        emit EventCancelled(_eventId, events[_eventId].externalId, msg.sender);
    }

    function purchaseTickets(
        uint _eventId,
        uint _quantity,
        string calldata _externalId,
        uint _timestamp,
        string calldata _customerId
    )
        external
        payable
        nonReentrant
        storeOpen
        eventOnSale(_eventId)
        returns (uint _purchaseId)
    {
        require(!Address.isContract(msg.sender), "a contract cannot purchase tickets");
        require(_quantity > 0, "quantity must be greater than zero");
        require(_quantity <= events[_eventId].ticketsLeft, "not enough tickets left");
        require(bytes(_externalId).length != 0, "purchase external ID must not be empty");
        require(_timestamp >= now - TIME_WINDOW && _timestamp <= now + TIME_WINDOW, "invalid purchase timestamp");
        require(bytes(_customerId).length != 0, "customer ID cannot be empty");
        require(msg.value == SafeMath.mul(_quantity, events[_eventId].ticketPrice), "funds not equal to total");
        _purchaseId = Counter.next(purchasesCounter);
        purchases[_purchaseId].status = PurchaseStatus.Completed;
        purchases[_purchaseId].eventId = _eventId;
        purchases[_purchaseId].quantity = _quantity;
        purchases[_purchaseId].externalId = keccak256(bytes(_externalId));
        purchases[_purchaseId].timestamp = _timestamp;
        purchases[_purchaseId].customer = msg.sender;
        purchases[_purchaseId].customerId = keccak256(bytes(_customerId));
        purchases[_purchaseId].total = SafeMath.mul(_quantity, events[_eventId].ticketPrice);
        events[_eventId].ticketsSold = SafeMath.add(events[_eventId].ticketsSold, _quantity);
        events[_eventId].ticketsLeft = SafeMath.sub(events[_eventId].ticketsLeft, _quantity);
        events[_eventId].eventBalance = SafeMath.add(events[_eventId].eventBalance, purchases[_purchaseId].total);
        emit PurchaseCompleted(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    function cancelPurchase(
        uint _purchaseId,
        string calldata _customerId,
        string calldata _externalId
    )
        external
        nonReentrant
        storeOpen
        purchaseCompleted(_purchaseId)
    {
        uint _eventId = purchases[_purchaseId].eventId;
        require(events[_eventId].status == EventStatus.SalesStarted ||
            events[_eventId].status == EventStatus.SalesSuspended ||
            events[_eventId].status == EventStatus.SalesFinished ||
            events[_eventId].status == EventStatus.Cancelled,
            "event status doesn't allow purchase cancellation");
        require(msg.sender == purchases[_purchaseId].customer, "only customer can cancel purchase");
        require(keccak256(bytes(_customerId)) == purchases[_purchaseId].customerId, "invalid customer ID");
        require(keccak256(bytes(_externalId)) == purchases[_purchaseId].externalId, "invalid external ID");
        purchases[_purchaseId].status = PurchaseStatus.Cancelled;
        events[_eventId].ticketsCancelled = SafeMath.add(events[_eventId].ticketsCancelled, purchases[_purchaseId].quantity);
        events[_eventId].ticketsLeft = SafeMath.add(events[_eventId].ticketsLeft, purchases[_purchaseId].quantity);
        events[_eventId].eventBalance = SafeMath.sub(events[_eventId].eventBalance, purchases[_purchaseId].total);
        events[_eventId].refundableBalance = SafeMath.add(events[_eventId].refundableBalance, purchases[_purchaseId].total);
        storeRefundableBalance = SafeMath.add(storeRefundableBalance, purchases[_purchaseId].total);
        emit PurchaseCancelled(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    function refundPurchase(uint _eventId, uint _purchaseId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
        purchaseCancelled(_purchaseId)
    {
        purchases[_purchaseId].status = PurchaseStatus.Refunded;
        events[_eventId].ticketsRefunded = SafeMath.add(events[_eventId].ticketsRefunded, purchases[_purchaseId].quantity);
        events[_eventId].refundableBalance = SafeMath.sub(events[_eventId].refundableBalance, purchases[_purchaseId].total);
        storeRefundableBalance = SafeMath.sub(storeRefundableBalance, purchases[_purchaseId].total);
        // TO-DO: transfer purchase refund to customer account
        emit PurchaseRefunded(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    function checkIn(uint _purchaseId)
        external
        nonReentrant
        storeOpen
        purchaseCompleted(_purchaseId)
    {
        uint _eventId = purchases[_purchaseId].eventId;
        require(events[_eventId].status == EventStatus.SalesStarted ||
            events[_eventId].status == EventStatus.SalesSuspended ||
            events[_eventId].status == EventStatus.SalesFinished,
            "event status doesn't allow check-in");
        require(msg.sender == purchases[_purchaseId].customer, "only customer can check-in");
        purchases[_purchaseId].status = PurchaseStatus.CheckedIn;
        emit CustomerCheckedIn(_eventId, _purchaseId, msg.sender);
    }
}
