pragma solidity ^0.5.1;

/// @author Fábio Corrêa (feamcor@gmail.com)
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
        address admin;
        uint eventCounter;
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
        address admin;
        string name;
        string timestamp;
        uint ticketsOnSale;
        uint ticketPrice;
        uint storeIncentive;
        uint ticketsSold;
        uint eventBalance;
        uint storeBalance;
        uint purchaseCounter;
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
    mapping(uint => mapping(uint => Purchase)) public purchases;

    event StoreCreated(address _by, address _admin);
    event StoreOpen(address _by);
    event StoreClosed(address _by);
    event StoreShutdown(address _by);
    event StoreAdminChanged(address _by, address _admin);

    event EventCreated(address _by, uint _eventId);
    event EventCancelled(address _by, uint _eventId);

    event TicketSalesStarted(address _by, uint _eventId);
    event TicketSalesSuspended(address _by, uint _eventId);
    event TicketSalesEnded(address _by, uint _eventId);

    event PurchaseCompleted(address _by, uint _eventId, uint _purchaseId);
    event PurchaseReverted(address _by, uint _eventId, uint _purchaseId);

    event CustomerCheckedIn(address _by, uint _eventId, uint _purchaseId);

    modifier onlyStoreOwner() {
        require(msg.sender == store.owner,
            "only owner can execute this action");
        _; 
    }

    modifier onlyStoreAdmin() {
        require(msg.sender == store.owner || msg.sender == store.admin,
            "only owner or admin can execute this action");
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

    modifier validPercentage(uint _percentage) {
        require(_percentage >= 0 && _percentage <= 10000,
            "percentage must be between 000 and 10000");
        _; 
    }

    modifier notEmpty(string memory _string) {
        require(bytes(_string).length != 0,
            "string must not be empty");
        _;
    }

    modifier notZero(uint _value) {
        require(_value > 0,
            "value must be greater than zero");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0x0),
            "invalid address");
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

    modifier onlyEventAdmin(uint _eventId) {
        require(msg.sender == events[_eventId].organizer || msg.sender == events[_eventId].admin,
            "only owner or admin can execute this action");
        _;
    }

    modifier eventNotCancelled(uint _eventId) {
        require(events[_eventId].status != EventStatus.Cancelled,
            "event was cancelled");
        _;
    }

    /// @notice Create a store with its respective owner, administrator and fee.
    /// @param _admin address of the administrator's account
    /// @dev store storeOwner is set by the account who created the store
    constructor(address _admin) public validAddress(_admin) {
        store.owner = msg.sender;
        store.admin = _admin;
        store.eventCounter = 0;
        store.status = StoreStatus.Created;
        emit StoreCreated(store.owner, store.admin);
    }

    function() external payable {
        require(msg.data.length == 0, "only funds transfer accepted");
    }

    function openStore() external onlyStoreAdmin storeNotShutdown storeClosed {
        store.status = StoreStatus.Open;
        emit StoreOpen(msg.sender);
    } 

    function closeStore() external onlyStoreAdmin storeNotShutdown storeOpen {
        store.status = StoreStatus.Closed;
        emit StoreClosed(msg.sender);
    }

    function shutdownStore() external onlyStoreOwner storeNotShutdown {
        store.status = StoreStatus.Shutdown;
        emit StoreShutdown(msg.sender);
    }

    function changeStoreAdmin(address _admin) external onlyStoreOwner storeNotShutdown {
        address _previous = store.admin;
        store.admin = _admin;
        emit StoreAdminChanged(_previous, _admin);
    }

    function createEvent(
        address _organizer,
        address _admin,
        string calldata _name,
        string calldata _timestamp,
        uint _ticketsOnSale,
        uint _ticketPrice,
        uint _storeIncentive
    )
        external
        onlyStoreAdmin
        storeNotShutdown
        storeOpen
        validAddress(_organizer)
        validAddress(_admin)
        notEmpty(_name)
        notEmpty(_timestamp)
        notZero(_ticketsOnSale)
        validPercentage(_storeIncentive)
        returns (uint)
    {
        store.eventCounter += 1;
        events[store.eventCounter].organizer = _organizer;
        events[store.eventCounter].admin = _admin;
        events[store.eventCounter].name = _name;
        events[store.eventCounter].timestamp = _timestamp;
        events[store.eventCounter].ticketsOnSale = _ticketsOnSale;
        events[store.eventCounter].ticketPrice = _ticketPrice;
        events[store.eventCounter].storeIncentive = _storeIncentive;
        events[store.eventCounter].ticketsSold = 0;
        events[store.eventCounter].eventBalance = 0;
        events[store.eventCounter].storeBalance = 0;
        events[store.eventCounter].purchaseCounter = 0;
        events[store.eventCounter].status = EventStatus.Created;
        emit EventCreated(msg.sender, store.eventCounter);
        return store.eventCounter;
    }

    function startTicketSales(uint _eventId)
        external
        storeOpen
        validEvent(_eventId)
        onlyEventAdmin(_eventId)
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
        onlyEventAdmin(_eventId)
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
        onlyEventAdmin(_eventId)
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
        onlyEventAdmin(_eventId)
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
        eventNotCancelled(_eventId)
        notZero(_quantity)
        notEmpty(_buyerId)
        notEmpty(_buyerName)
        notEmpty(_timestamp)
        notEmpty(_externalId)
        returns (uint)
    {
        require(events[_eventId].status == EventStatus.TicketSalesStarted,
            "tickets not on sale for this event");
        require(msg.value >= events[_eventId].ticketPrice * _quantity,
            "not enough balance for purchase");
        events[_eventId].purchaseCounter += 1;
        purchases[_eventId][events[_eventId].purchaseCounter].buyer = msg.sender;
        purchases[_eventId][events[_eventId].purchaseCounter].buyerId = _buyerId;
        purchases[_eventId][events[_eventId].purchaseCounter].buyerName = _buyerName;
        purchases[_eventId][events[_eventId].purchaseCounter].timestamp = _timestamp;
        purchases[_eventId][events[_eventId].purchaseCounter].externalId = _externalId;
        purchases[_eventId][events[_eventId].purchaseCounter].quantity = _quantity;
        purchases[_eventId][events[_eventId].purchaseCounter].total = events[_eventId].ticketPrice * _quantity;
        purchases[_eventId][events[_eventId].purchaseCounter].status = PurchaseStatus.Completed;
        emit PurchaseCompleted(msg.sender, _eventId, events[_eventId].purchaseCounter);
        return events[_eventId].purchaseCounter;
    }
}
