pragma solidity 0.5.2;

/// @author Fábio Corrêa <feamcor@gmail.com>
/// @title A simple decentralized ticket store on Ethereum
contract Bileto {
    enum StoreStatus {
        Created,
        Open,
        Closed,
        Shutdown
    }

    struct Store {
        address owner;
        uint eventCounter;
        uint purchaseCounter;
        StoreStatus status;
    }

    enum EventStatus {
        Created,
        TicketSalesStarted,
        TicketSalesSuspended,
        TicketSalesEnded,
        Cancelled
    }

    struct Event {
        address organizer;
        string name;
        string timestamp;
        uint ticketsOnSale;
        uint ticketPrice;
        uint storeIncentive;
        uint ticketsSold;
        uint eventBalance;
        uint storeBalance;
        EventStatus status;
    }

    enum PurchaseStatus {
        Completed,
        Reverted,
        CheckedIn
    }

    struct Purchase {
        address buyer;
        string buyerId;
        string buyerName;
        string timestamp;
        string externalId;
        uint quantity;
        uint total;
        PurchaseStatus status;
    }

    Store public store;
    mapping(uint => Event) public events;
    mapping(uint => Purchase) public purchases;

    event StoreCreated(address indexed _by);
    event StoreOpen(address indexed _by);
    event StoreClosed(address indexed _by);
    event StoreShutdown(address indexed _by);

    event EventCreated(address indexed _by, uint indexed _eventId);
    event EventCancelled(address indexed _by, uint indexed _eventId);

    event TicketSalesStarted(address indexed _by, uint indexed _eventId);
    event TicketSalesSuspended(address indexed _by, uint indexed _eventId);
    event TicketSalesEnded(address indexed _by, uint indexed _eventId);

    event PurchaseCompleted(address indexed _by, uint indexed _eventId, uint indexed _purchaseId);
    event PurchaseReverted(address indexed _by, uint indexed _eventId, uint indexed _purchaseId);

    event CustomerCheckedIn(address indexed _by, uint indexed _eventId, uint indexed _purchaseId);

    modifier onlyOwner() {
        require(msg.sender == store.owner,
            "only owner can execute this action");
        _; 
    }

    modifier storeNotShutdown() {
        require(store.status != StoreStatus.Shutdown,
            "action not allowed. store was shutdown");
        _;
    }

    modifier storeOpen() {
        require(store.status == StoreStatus.Open,
            "action only allowed when store is open");
        _;
    }

    modifier storeClosed() {
        require(store.status == StoreStatus.Closed,
            "action only allowed when store is closed");
        _;
    }

    modifier validEvent(uint _eventId) {
        require(_eventId <= store.eventCounter,
            "invalid event id");
        _;
    }

    modifier onlyOrganizer(uint _eventId) {
        require(msg.sender == events[_eventId].organizer,
            "only organizer can execute this action");
        _; 
    }

    modifier eventNotCancelled(uint _eventId) {
        require(events[_eventId].status != EventStatus.Cancelled,
            "event was cancelled");
        _;
    }

    modifier eventOnSale(uint _eventId) {
        require(events[_eventId].status == EventStatus.TicketSalesStarted,
            "tickets not on sale for this event");
        _;
    }

    /// @notice Create a store with its respective owner.
    /// @dev store owner is set by the account who created the store
    constructor() public {
        store.owner = msg.sender;
        store.eventCounter = 0;
        store.status = StoreStatus.Created;
        emit StoreCreated(store.owner);
    }

    function() external payable {
        require(msg.data.length == 0, "only funds transfer accepted");
    }

    function openStore() external onlyOwner storeNotShutdown {
        store.status = StoreStatus.Open;
        emit StoreOpen(msg.sender);
    } 

    function closeStore() external onlyOwner storeOpen {
        store.status = StoreStatus.Closed;
        emit StoreClosed(msg.sender);
    }

    function shutdownStore() external onlyOwner storeNotShutdown {
        store.status = StoreStatus.Shutdown;
        emit StoreShutdown(msg.sender);
    }

    function createEvent(
        address _organizer,
        string calldata _name,
        string calldata _timestamp,
        uint _ticketsOnSale,
        uint _ticketPrice,
        uint _storeIncentive
    )
        external
        onlyOwner
        storeOpen
        returns (uint _eventId)
    {
        require(_organizer != address(0x0), "invalid organizer address");
        require(bytes(_name).length != 0, "event name must not be empty");
        require(bytes(_timestamp).length != 0, "event creation timestamp must not be empty");
        require(_ticketsOnSale > 0, "number of tickets on sale cannot be zero");
        require(_storeIncentive >= 0 && _storeIncentive <= 10000, "invalid store incentive");
        store.eventCounter += 1;
        _eventId = store.eventCounter;
        events[_eventId].organizer = _organizer;
        events[_eventId].name = _name;
        events[_eventId].timestamp = _timestamp;
        events[_eventId].ticketsOnSale = _ticketsOnSale;
        events[_eventId].ticketPrice = _ticketPrice;
        events[_eventId].storeIncentive = _storeIncentive;
        events[_eventId].status = EventStatus.Created;
        emit EventCreated(msg.sender, _eventId);
    }

    function startTicketSales(uint _eventId)
        external
        storeOpen
        validEvent(_eventId)
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.TicketSalesSuspended,
            "cannot start ticket sale for this event");
        events[_eventId].status = EventStatus.TicketSalesStarted;
        emit TicketSalesStarted(msg.sender, _eventId);
    }

    function suspendTicketSales(uint _eventId)
        external
        storeOpen
        validEvent(_eventId)
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.TicketSalesStarted,
            "cannot suspend ticket sale for this event");
        events[_eventId].status = EventStatus.TicketSalesSuspended;
        emit TicketSalesSuspended(msg.sender, _eventId);
    }

    function endTicketSales(uint _eventId)
        external
        storeOpen
        validEvent(_eventId)
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        require(events[_eventId].status == EventStatus.TicketSalesStarted ||
            events[_eventId].status == EventStatus.TicketSalesSuspended,
            "cannot end ticket sale for this event");
        events[_eventId].status = EventStatus.TicketSalesEnded;
        emit TicketSalesEnded(msg.sender, _eventId);
    }

    function cancelEvent(uint _eventId)
        external
        storeOpen
        validEvent(_eventId)
        onlyOrganizer(_eventId)
        eventNotCancelled(_eventId)
    {
        events[_eventId].status = EventStatus.Cancelled;
        emit EventCancelled(msg.sender, _eventId);
    }

    function purchaseTickets(
        uint _eventId,
        uint _quantity,
        string calldata _buyerId,
        string calldata _buyerName,
        string calldata _timestamp,
        string calldata _externalId
    )
        external
        payable
        storeOpen
        validEvent(_eventId)
        eventOnSale(_eventId)
        returns (uint _purchaseId)
    {
        require(_quantity > 0, "quantity must be greater than zero");
        require(bytes(_buyerId).length != 0, "buyer ID must not be empty");
        require(bytes(_buyerName).length != 0, "buyer name must not be empty");
        require(bytes(_timestamp).length != 0, "purchase timestamp must not be empty");
        require(bytes(_externalId).length != 0, "purchase external ID must not be empty");
        uint _total = _quantity * events[_eventId].ticketPrice;
        require(msg.value >= _total, "not enough balance for purchase");
        store.purchaseCounter += 1;
        _purchaseId = store.purchaseCounter;
        purchases[_purchaseId].buyer = msg.sender;
        purchases[_purchaseId].buyerId = _buyerId;
        purchases[_purchaseId].buyerName = _buyerName;
        purchases[_purchaseId].timestamp = _timestamp;
        purchases[_purchaseId].externalId = _externalId;
        purchases[_purchaseId].quantity = _quantity;
        purchases[_purchaseId].total = _total;
        purchases[_purchaseId].status = PurchaseStatus.Completed;
        emit PurchaseCompleted(msg.sender, _eventId, _purchaseId);
    }
}
