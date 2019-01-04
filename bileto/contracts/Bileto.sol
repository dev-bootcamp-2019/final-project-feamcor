pragma solidity 0.5.2;

import "./Ownable.sol";
import "./Counter.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

/// @author Fábio Corrêa <feamcor@gmail.com>
/// @title Bileto: a simple decentralized ticket store on Ethereum
/// @notice Final project for ConsenSys Academy's Developer Bootcamp 2019.
contract Bileto is Ownable, ReentrancyGuard {
    enum StoreStatus {
        Created,   // 0
        Open,      // 1
        Suspended, // 2
        Closed     // 3
    }

    enum EventStatus {
        Created,        // 0
        SalesStarted,   // 1
        SalesSuspended, // 2
        SalesFinished,  // 3
        Completed,      // 4
        Settled,        // 5
        Cancelled       // 6
    }

    enum PurchaseStatus {
        Completed, // 0
        Cancelled, // 1
        Refunded,  // 2
        CheckedIn  // 3
    }

    struct Event {
        EventStatus status;
        bytes32 externalId;
        address payable organizer;
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
        address payable customer;
        bytes32 customerId;
        uint quantity;
        uint total;
        uint eventId;
    }

    uint constant private TIME_WINDOW = 15 * 60; // 15 minutes before and after now

    StoreStatus public storeStatus;
    uint public storeRefundableBalance;

    Counter.Counter_ public eventsCounter;
    mapping(uint => Event) public events;

    Counter.Counter_ public purchasesCounter;
    mapping(uint => Purchase) public purchases;

    /// @notice Ticket store was opened.
    /// @param _by store's owner address (indexed)
    /// @dev corresponds to `StoreStatus.Open`
    event StoreOpen(address indexed _by);

    /// @notice Ticket store was suspended.
    /// @param _by store's owner address (indexed)
    /// @dev corresponds to `StoreStatus.Suspended`
    event StoreSuspended(address indexed _by);

    /// @notice Ticket store was closed.
    /// @param _by store's owner address (indexed)
    /// @dev corresponds to `StoreStatus.Closed`
    event StoreClosed(address indexed _by);

    /// @notice Ticket event was created.
    /// @param _id event's new internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by store's owner address (indexed)
    /// @dev corresponds to `EventStatus.Created`
    event EventCreated(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Event's ticket sales was started.
    /// @param _id event's internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by events's organizer address (indexed)
    /// @dev corresponds to `EventStatus.SalesStarted`
    event EventSalesStarted(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Event's ticket sales was suspended.
    /// @param _id event's internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by events's organizer address (indexed)
    /// @dev corresponds to `EventStatus.SalesSuspended`
    event EventSalesSuspended(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Event's ticket sales was finished.
    /// @param _id event's internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by events's organizer address (indexed)
    /// @dev corresponds to `EventStatus.SalesFinished`
    event EventSalesFinished(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Ticket event was completed.
    /// @param _id event's new internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by events's organizer address (indexed)
    /// @dev corresponds to `EventStatus.Completed`
    event EventCompleted(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Ticket event was settled.
    /// @param _id event's internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by store's owner address (indexed)
    /// @param _settlement amount settled (transferred) to event's organizer
    /// @dev corresponds to `EventStatus.Settled`
    event EventSettled(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _settlement);

    /// @notice Ticket event was cancelled.
    /// @param _id event's internal ID (indexed) 
    /// @param _extId hash of the event's external ID (indexed)
    /// @param _by event's organizer address (indexed)
    /// @dev corresponds to `EventStatus.Cancelled`
    event EventCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by);

    /// @notice Ticket purchase was completed.
    /// @param _id purchase's new internal ID (indexed) 
    /// @param _extId hash of the purchase's external ID (indexed)
    /// @param _by customer's address (indexed)
    /// @param _id event's internal ID 
    /// @dev corresponds to `PurchaseStatus.Completed`
    event PurchaseCompleted(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);

    /// @notice Ticket purchase was cancelled.
    /// @param _id purchase's internal ID (indexed) 
    /// @param _extId hash of the purchase's external ID (indexed)
    /// @param _by customer's address (indexed)
    /// @param _id event's internal ID 
    /// @dev corresponds to `PurchaseStatus.Cancelled`
    event PurchaseCancelled(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);

    /// @notice Ticket purchase was refunded.
    /// @param _id purchase's internal ID (indexed) 
    /// @param _extId hash of the purchase's external ID (indexed)
    /// @param _by customer's address (indexed)
    /// @param _id event's internal ID 
    /// @dev corresponds to `PurchaseStatus.Refunded`
    event PurchaseRefunded(uint indexed _id, bytes32 indexed _extId, address indexed _by, uint _eventId);

    /// @notice Customer checked in the event.
    /// @param _eventId event's internal ID (indexed)
    /// @param _purchaseId purchase's internal ID (indexed) 
    /// @param _by customer's address (indexed)
    /// @dev corresponds to `PurchaseStatus.CheckedIn`
    event CustomerCheckedIn(uint indexed _eventId, uint indexed _purchaseId, address indexed _by);

    /// @dev Verify that ticket store is open, otherwise revert.
    modifier storeOpen() {
        require(storeStatus == StoreStatus.Open,
            "ticket store must be open in order to proceed");
        _;
    }

    /// @dev Verify that transaction on an event was triggered by its organizer, otherwise revert.
    modifier onlyOrganizer(uint _eventId) {
        require(_eventId <= eventsCounter.current &&
            msg.sender == events[_eventId].organizer,
            "must be triggered by event organizer in order to proceed");
        _;
    }

    /// @dev Verify that transaction on an event was triggered by its organizer or store owner.
    modifier onlyOwnerOrOrganizer(uint _eventId) {
        require(isOwner() ||
            (_eventId <= eventsCounter.current &&
            msg.sender == events[_eventId].organizer),
            "must be triggered by event organizer or store owner in order to proceed");
        _;
    }

    /// @dev Verify that transaction on a purchase was triggered by the customer, event organizer or store owner.
    modifier onlyOwnerOrganizerOrCustomer(uint _purchaseId) {
        require(isOwner() ||
            (_purchaseId <= purchasesCounter.current && msg.sender == purchases[_purchaseId].customer) ||
            (msg.sender == events[purchases[_purchaseId].eventId].organizer),
            "must be triggered by customer, event organizer or store owner in order to proceed");
        _;
    }

    /// @dev Verify that tickets of an event are on sale (have started), otherwise revert.
    modifier eventOnSale(uint _eventId) {
        require(_eventId <= eventsCounter.current &&
            events[_eventId].status == EventStatus.SalesStarted,
            "event ticket sales have to had started in order to proceed");
        _;
    }

    /// @dev Verify that a purchase was completed, otherwise revert.
    modifier purchaseCompleted(uint _purchaseId) {
        require(_purchaseId <= purchasesCounter.current &&
            purchases[_purchaseId].status == PurchaseStatus.Completed,
            "ticket purchase have to be completed in order to proceed");
        _;
    }

    /// @dev Verify that a purchase was cancelled, otherwise revert.
    modifier purchaseCancelled(uint _purchaseId) {
        require(_purchaseId <= purchasesCounter.current &&
            purchases[_purchaseId].status == PurchaseStatus.Cancelled,
            "ticket purchase have to be cancelled in order to proceed");
        _;
    }

    /// @notice Initialize the ticket store and its respective owner.
    /// @dev store owner is set by the account who created the store
    constructor() public {
        storeStatus = StoreStatus.Created;
    }

    /// @notice Fallback function.
    function()
        external
        payable
    {
        require(msg.data.length == 0, "only funds transfer (i.e. no data) accepted on fallback");
    }

    /// @notice Open ticket store.
    /// @dev emit `StoreOpen` event
    function openStore()
        external
        nonReentrant
        onlyOwner
    {
        require(storeStatus == StoreStatus.Created ||
            storeStatus == StoreStatus.Suspended,
            "ticket store must be created or suspended in order to proceed");
        storeStatus = StoreStatus.Open;
        emit StoreOpen(owner());
    }

    /// @notice Suspend ticket store.
    /// @notice Should be used with extreme caution and on exceptional cases only.
    /// @dev emit `StoreSuspended` event
    function suspendStore()
        external
        nonReentrant
        onlyOwner
        storeOpen
    {
        storeStatus = StoreStatus.Suspended;
        emit StoreSuspended(owner());
    }

    /// @notice Close ticket store.
    /// @notice This is ticket store's final state and become inoperable after.
    /// @notice Ticket store won't close while there are refundable balance left.
    /// @dev emit `StoreClosed` event
    function closeStore()
        external
        nonReentrant
        onlyOwner
    {
        require(storeStatus != StoreStatus.Closed,
            "ticket store cannot be closed in order to proceed");
        require(storeRefundableBalance == 0,
            "ticket store's refundable balance must be zero in order to proceed");
        storeStatus = StoreStatus.Closed;
        emit StoreClosed(owner());
    }

    /// @notice Create a ticket event.
    /// @param _externalId event's external ID provided by organizer. Will be stored hashed
    /// @param _organizer event's organizer address. Will be able to manage the event thereafter
    /// @param _name event's name
    /// @param _storeIncentive commission granted to store upon sale of tickets. From 0.00% (000) to 100.00% (10000)
    /// @param _ticketPrice ticket price (in wei)
    /// @param _ticketsOnSale number of tickets available for sale
    /// @return event's internal ID
    /// @dev emit `EventCreated` event
    function createEvent(
        string calldata _externalId,
        address payable _organizer,
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
        require(!Address.isContract(_organizer),
            "organizer's address must refer to an account (i.e. not a contract) in order to proceed");
        require(bytes(_externalId).length != 0,
            "ticket event's external ID must not be empty in order to proceed");
        require(bytes(_name).length != 0,
            "ticket event's name must not be empty in order to proceed");
        require(_storeIncentive >= 0 && _storeIncentive <= 10000,
            "store incentive must be between 0.00% (000) to 100.00% (10000) in order to proceed");
        require(_ticketsOnSale > 0,
            "number of tickets available for sale cannot be zero in order to proceed");
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
        return (_eventId);
    }

    /// @notice Start sale of tickets for an event.
    /// @param _eventId event's internal ID
    /// @dev emit `EventSalesStarted` event
    function startTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "ticket event must be created or with sales suspended in order to proceed");
        events[_eventId].status = EventStatus.SalesStarted;
        emit EventSalesStarted(_eventId, events[_eventId].externalId, msg.sender);
    }

    /// @notice Suspend sale of tickets for an event.
    /// @param _eventId event's internal ID
    /// @dev emit `EventSalesSuspended` event
    function suspendTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted,
            "event ticket sales must have started in order to proceed");
        events[_eventId].status = EventStatus.SalesSuspended;
        emit EventSalesSuspended(_eventId, events[_eventId].externalId, msg.sender);
    }

    /// @notice End sale of tickets for an event.
    /// @notice It means that no tickets for the event can be sold thereafter.
    /// @param _eventId event's internal ID
    /// @dev emit `EventSalesFinished` event
    function endTicketSales(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesStarted ||
            events[_eventId].status == EventStatus.SalesSuspended,
            "event ticket sales must have started or be suspended in order to proceed");
        events[_eventId].status = EventStatus.SalesFinished;
        emit EventSalesFinished(_eventId, events[_eventId].externalId, msg.sender);
    }

    /// @notice Complete an event.
    /// @notice It means that the event is past and can be settled (paid out to organizer).
    /// @param _eventId event's internal ID
    /// @dev emit `EventCompleted` event
    function completeEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.SalesFinished, 
            "event ticket sales must have finished in order to proceed");
        events[_eventId].status = EventStatus.Completed;
        emit EventCompleted(_eventId, events[_eventId].externalId, msg.sender);
    }

    /// @notice Settle an event.
    /// @notice It means that (non-refundable) funds will be transferred to organizer.
    /// @notice No transfer will be performed if settlement balance is zero,
    /// @notice even though event will be considered settled.
    /// @param _eventId event's internal ID
    /// @dev emit `EventSettled` event
    function settleEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOwner
    {
        require(events[_eventId].status == EventStatus.Completed,
            "ticket event must have been completed in order to proceed");
        events[_eventId].status = EventStatus.Settled;
        uint _eventBalance = events[_eventId].eventBalance;
        uint _storeIncentive = events[_eventId].storeIncentive;
        uint _storeBalance = SafeMath.div(SafeMath.mul(_eventBalance, _storeIncentive), 10000);
        uint _settlement = SafeMath.sub(_eventBalance, _storeBalance);
        if (_settlement > 0) {
            events[_eventId].organizer.transfer(_settlement);
        }
        emit EventSettled(_eventId, events[_eventId].externalId, msg.sender, _settlement);
    }

    /// @notice Cancel an event.
    /// @notice It means that ticket sales will stop and sold tickets (purchases) are refundable.
    /// @param _eventId event's internal ID
    /// @dev emit `EventCancelled` event
    function cancelEvent(uint _eventId)
        external
        nonReentrant
        storeOpen
        onlyOrganizer(_eventId)
    {
        require(events[_eventId].status == EventStatus.Created ||
            events[_eventId].status == EventStatus.SalesFinished,
            "event must have just be created or have its ticket sales suspended in order to proceed");
        events[_eventId].status = EventStatus.Cancelled;
        emit EventCancelled(_eventId, events[_eventId].externalId, msg.sender);
    }

    /// @notice Purchase one or more tickets.
    /// @param _eventId event's internal ID
    /// @param _quantity number of tickets being purchase at once. It has to be greater than zero and available
    /// @param _externalId purchase's external ID (usually for correlation). Cannot be empty. Will be stored hashed
    /// @param _timestamp purchase's date provided by organizer (UNIX epoch)
    /// @param _customerId ID of the customer provided during purchase. Cannot be empty. Will be store hashed
    /// @return purchase's internal ID
    /// @dev emit `PurchaseCompleted` event
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
        require(!Address.isContract(msg.sender),
            "customer's address must refer to an account (i.e. not a contract) in order to proceed");
        require(_quantity > 0,
            "quantity of tickets must be greater than zero in order to proceed");
        require(_quantity <= events[_eventId].ticketsLeft,
            "not enough tickets left for the quantity requested. please change quantity in order to proceed");
        require(bytes(_externalId).length != 0,
            "purchase's external ID must not be empty in order to proceed");
        require(_timestamp >= now - TIME_WINDOW && _timestamp <= now + TIME_WINDOW,
            "purchase's date must be within valid time window in order to proceed");
        require(bytes(_customerId).length != 0,
            "customer ID cannot be empty in order to proceed");
        require(msg.value == SafeMath.mul(_quantity, events[_eventId].ticketPrice),
            "customer's funds sent on transaction must be equal to purchase's total in order to proceed");
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
        return (_purchaseId);
    }

    /// @notice Cancel a purchase.
    /// @notice Other IDs are required in order to avoid fraudulent cancellations.
    /// @param _purchaseId purchase's internal ID
    /// @param _externalId purchase's external ID which will be hashed and then compared to store one
    /// @param _customerId purchase's customer ID which will be hashed and then compared to store one
    /// @dev emit `PurchaseCancelled` event
    function cancelPurchase(
        uint _purchaseId,
        string calldata _externalId,
        string calldata _customerId
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
            "event status must allow cancellation in order to proceed");
        require(msg.sender == purchases[_purchaseId].customer,
            "purchase cancellation must be initiated by purchase's customer in order to proceed");
        require(keccak256(bytes(_customerId)) == purchases[_purchaseId].customerId,
            "hashed customer ID must match with stored one in order to proceed");
        require(keccak256(bytes(_externalId)) == purchases[_purchaseId].externalId,
            "hashed purchase's external ID must match with stored one in order to proceed");
        purchases[_purchaseId].status = PurchaseStatus.Cancelled;
        events[_eventId].ticketsCancelled = SafeMath.add(events[_eventId].ticketsCancelled, purchases[_purchaseId].quantity);
        events[_eventId].ticketsLeft = SafeMath.add(events[_eventId].ticketsLeft, purchases[_purchaseId].quantity);
        events[_eventId].eventBalance = SafeMath.sub(events[_eventId].eventBalance, purchases[_purchaseId].total);
        events[_eventId].refundableBalance = SafeMath.add(events[_eventId].refundableBalance, purchases[_purchaseId].total);
        storeRefundableBalance = SafeMath.add(storeRefundableBalance, purchases[_purchaseId].total);
        emit PurchaseCancelled(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    /// @notice Refund a cancelled purchase to customer.
    /// @param _eventId internal ID of the event associated to the purchase
    /// @param _purchaseId purchase's internal ID
    /// @dev emit `PurchaseRefunded` event
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
        purchases[_purchaseId].customer.transfer(purchases[_purchaseId].total);
        emit PurchaseRefunded(_purchaseId, purchases[_purchaseId].externalId, msg.sender, _eventId);
    }

    /// @notice Check into an event.
    /// @notice It means that customer and his/her companions (optional) attended to the event.
    /// @param _purchaseId purchase's internal ID
    /// @dev emit `CustomerCheckedIn` event
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
            "event ticket's sales should have been started/suspended/finished in order to proceed");
        require(msg.sender == purchases[_purchaseId].customer,
            "check-in request must be initiated from customer's own account in order to proceed");
        purchases[_purchaseId].status = PurchaseStatus.CheckedIn;
        emit CustomerCheckedIn(_eventId, _purchaseId, msg.sender);
    }

    /// @notice Fetch event basic information.
    /// @notice Basic info are those static attributes set when event is created.
    /// @param _eventId event's internal ID
    /// @return event's status
    /// @return event's external ID
    /// @return event organizer's address
    /// @return event's name
    /// @return store incentive for the event
    /// @return event's ticket price
    /// @return quantity of tickets on sale for the event
    function fetchEventInfo(uint _eventId)
        external
        view
        onlyOwnerOrOrganizer(_eventId)
        returns (
            uint _eventStatus,
            bytes32 _externalId,
            address _organizer,
            string memory _name,
            uint _storeIncentive,
            uint _ticketPrice,
            uint _ticketsOnSale
        )
    {
        _eventStatus = uint(events[_eventId].status);
        _externalId = events[_eventId].externalId;
        _organizer = events[_eventId].organizer;
        _name = events[_eventId].name;
        _storeIncentive = events[_eventId].storeIncentive;
        _ticketPrice = events[_eventId].ticketPrice;
        _ticketsOnSale = events[_eventId].ticketsOnSale;
    }

    /// @notice Fetch event sales information.
    /// @notice Sales info are those attributes which change upon each purchase/cancellation transaction.
    /// @param _eventId event's internal ID
    /// @return event's status
    /// @return quantity of tickets sold for the event
    /// @return quantity of tickets available for sale
    /// @return quantity of tickets that were sold and then cancelled
    /// @return quantity of cancelled tickets that were already refunded
    /// @return quantity of tickets that already checked into the event
    /// @return balance of the event resulting from sales of tickets
    /// @return balance to be refunded due to cancellations
    function fetchEventSalesInfo(uint _eventId)
        external
        view
        onlyOwnerOrOrganizer(_eventId)
        returns (
            uint _eventStatus,
            uint _ticketsSold,
            uint _ticketsLeft,
            uint _ticketsCancelled,
            uint _ticketsRefunded,
            uint _ticketsCheckedIn,
            uint _eventBalance,
            uint _refundableBalance
        )
    {
        _eventStatus = uint(events[_eventId].status);
        _ticketsSold = events[_eventId].ticketsSold;
        _ticketsLeft = events[_eventId].ticketsLeft;
        _ticketsCancelled = events[_eventId].ticketsCancelled;
        _ticketsRefunded = events[_eventId].ticketsRefunded;
        _ticketsCheckedIn = events[_eventId].ticketsCheckedIn;
        _eventBalance = events[_eventId].eventBalance;
        _refundableBalance = events[_eventId].refundableBalance;
    }

    /// @notice Fetch purchase information.
    /// @param _purchaseId purchase's internal ID
    /// @return purchase's status
    /// @return hash of purchase's external ID
    /// @return purchase's external timestamp
    /// @return customer's address
    /// @return hash of customer's external ID
    /// @return quantity of tickets purchased
    /// @return total of purchase (quantity * ticket price)
    /// @return ID of the event related to the purchase
    function fetchPurchaseInfo(uint _purchaseId)
        external
        view
        onlyOwnerOrganizerOrCustomer(_purchaseId)
        returns (
            uint _purchaseStatus,
            bytes32 _externalId,
            uint _timestamp,
            address _customer,
            bytes32 _customerId,
            uint _quantity,
            uint _total,
            uint _eventId
        )
    {
        _purchaseStatus = uint(purchases[_purchaseId].status);
        _externalId = purchases[_purchaseId].externalId;
        _timestamp = purchases[_purchaseId].timestamp;
        _customer = purchases[_purchaseId].customer;
        _customerId = purchases[_purchaseId].customerId;
        _quantity = purchases[_purchaseId].quantity;
        _total = purchases[_purchaseId].total;
        _eventId = purchases[_purchaseId].eventId;
    }
}
