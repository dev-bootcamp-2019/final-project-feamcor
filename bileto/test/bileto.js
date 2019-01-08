const truffleAssert = require("truffle-assertions");
const Bileto = artifacts.require("Bileto");

contract("Bileto", async accounts => {
  let __contract;
  let __address;
  let __balance;
  let __status;
  let __refundable;
  let __lastEvent;
  let __lastPurchase;
  let __timestamp = new Date().getTime();
  const __owner = accounts[0];
  const __organizer1 = accounts[1];
  const __customer1 = accounts[2];

  before(async () => {
    __contract = await Bileto.deployed();
    __address = __contract.address;
    let _counter = 0;
    for (let _account of accounts) {
      const _balance = await web3.eth.getBalance(_account);
      console.log(
        "account[" +
          _counter +
          "]:\t" +
          _account +
          " = " +
          web3.utils.fromWei(_balance, "ether")
      );
      _counter += 1;
      if (_counter == 3) break;
    }
    console.log("store address:\t" + __address);
    console.log("store owner:\t" + __owner);
  });

  beforeEach(async () => {
    __status = await __contract.storeStatus();
    __balance = await web3.eth.getBalance(__address);
    __refundable = await __contract.storeRefundableBalance();
    __lastEvent = await __contract.eventsCounter();
    __lastPurchase = await __contract.purchasesCounter();
  });

  it("should create store", async () => {
    assert.strictEqual(
      __status.toNumber(),
      0,
      "store status is not StoreStatus.Created (0)"
    );
    assert.strictEqual(__balance, "0", "store balance is not zero");
    assert.strictEqual(
      __refundable.toNumber(),
      0,
      "store refundable balance is not zero"
    );
  });

  it("should not open store for non-owner", async () => {
    await truffleAssert.reverts(
      __contract.openStore({
        from: __organizer1
      })
    );
  });

  it("should open store", async () => {
    const _result = await __contract.openStore();
    __status = await __contract.storeStatus();
    assert.strictEqual(
      __status.toNumber(),
      1,
      "store status is not StoreStatus.Open (1)"
    );
    truffleAssert.eventEmitted(_result, "StoreOpen");
  });

  it("should not suspend store for non-owner", async () => {
    await truffleAssert.reverts(
      __contract.suspendStore({
        from: __organizer1
      })
    );
  });

  it("should suspend store", async () => {
    const _result = await __contract.suspendStore();
    __status = await __contract.storeStatus();
    assert.strictEqual(
      __status.toNumber(),
      2,
      "store status is not StoreStatus.Open (2)"
    );
    truffleAssert.eventEmitted(_result, "StoreSuspended");
  });

  it("should re-open store", async () => {
    const _result = await __contract.openStore();
    __status = await __contract.storeStatus();
    assert.strictEqual(
      __status.toNumber(),
      1,
      "store status is not StoreStatus.Open (1)"
    );
    truffleAssert.eventEmitted(_result, "StoreOpen");
  });

  it("should not create an event for non-owner", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "BILETO-EVENT-1",
        __organizer1,
        "BILETO EVENT 1",
        1000,
        web3.utils.toWei("0.1", "ether"),
        10,
        {
          from: __organizer1
        }
      )
    );
  });

  it("should not create an event when organizer is a contract", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "BILETO-EVENT-1",
        __address,
        "BILETO EVENT 1",
        1000,
        web3.utils.toWei("0.1", "ether"),
        10
      )
    );
  });

  it("should not create an event without external ID", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "",
        __organizer1,
        "BILETO EVENT 1",
        1000,
        web3.utils.toWei("0.1", "ether"),
        10
      )
    );
  });

  it("should not create an event without name", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "BILETO-EVENT-1",
        __organizer1,
        "",
        1000,
        web3.utils.toWei("0.1", "ether"),
        10
      )
    );
  });

  it("should not create an event with incentive greater than 100%", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "BILETO-EVENT-1",
        __organizer1,
        "BILETO EVENT 1",
        10001,
        web3.utils.toWei("0.1", "ether"),
        10
      )
    );
  });

  it("should not create an event with no tickets available for sale", async () => {
    await truffleAssert.reverts(
      __contract.createEvent(
        "BILETO-EVENT-1",
        __organizer1,
        "BILETO EVENT 1",
        1000,
        web3.utils.toWei("0.1", "ether"),
        0
      )
    );
  });

  it("should create an event", async () => {
    const _result = await __contract.createEvent(
      "BILETO-EVENT-1",
      __organizer1,
      "BILETO EVENT 1",
      1000,
      web3.utils.toWei("0.1", "ether"),
      10
    );
    const _eventId = await __contract.eventsCounter();
    const _info = await __contract.fetchEventInfo.call(_eventId);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      0,
      "event status is not EventStatus.Created (0)"
    );
    truffleAssert.eventEmitted(_result, "EventCreated");
  });

  it("should store event basic info accordingly", async () => {
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    const _hash = web3.utils.keccak256("BILETO-EVENT-1");
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      0,
      "event status is not EventStatus.Created (0)"
    );
    assert.strictEqual(
      _info._externalId,
      _hash,
      "event external ID hash is incorrect"
    );
    assert.strictEqual(
      _info._organizer,
      __organizer1,
      "event organizer address is incorrect"
    );
    assert.strictEqual(
      _info._name,
      "BILETO EVENT 1",
      "event name is incorrect"
    );
    assert.strictEqual(
      _info._storeIncentive.toNumber(),
      1000,
      "event store incentive is incorrect"
    );
    assert.strictEqual(
      _info._ticketPrice.toString(),
      web3.utils.toWei("0.1", "ether"),
      "event ticket price is incorrect"
    );
    assert.strictEqual(
      _info._ticketsOnSale.toNumber(),
      10,
      "event tickets on sale is incorrect"
    );
  });

  it("should init event sales info accordingly", async () => {
    const _basic = await __contract.fetchEventInfo.call(__lastEvent);
    const _info = await __contract.fetchEventSalesInfo.call(__lastEvent);
    assert.strictEqual(
      _info._ticketsSold.toNumber(),
      0,
      "event tickets sold should be zero"
    );
    assert.strictEqual(
      _info._ticketsLeft.toNumber(),
      _basic._ticketsOnSale.toNumber(),
      "event tickets left should be equal to tickets on sale"
    );
    assert.strictEqual(
      _info._ticketsCancelled.toNumber(),
      0,
      "event tickets cancelled should be zero"
    );
    assert.strictEqual(
      _info._ticketsRefunded.toNumber(),
      0,
      "event tickets refunded should be zero"
    );
    assert.strictEqual(
      _info._ticketsCheckedIn.toNumber(),
      0,
      "event tickets checked-in should be zero"
    );
    assert.strictEqual(
      _info._eventBalance.toNumber(),
      0,
      "event balance should be zero"
    );
    assert.strictEqual(
      _info._refundableBalance.toNumber(),
      0,
      "event refundable balance should be zero"
    );
  });

  it("should not complete purchase sales not started yet", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should start ticket sales of an event", async () => {
    const _result = await __contract.startTicketSales(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      1,
      "event status is not EventStatus.SalesStarted (1)"
    );
    truffleAssert.eventEmitted(_result, "EventSalesStarted");
  });

  it("should not complete purchase when quantity is zero", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        0,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should not complete purchase when there are not enough tickets", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        100,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should not complete purchase without external ID", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should not complete purchase without timestamp", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "BILETO-EVENT-1-PURCHASE-1",
        0,
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should not complete purchase without customer ID", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "",
        {
          from: __customer1,
          value: web3.utils.toWei("0.1", "ether")
        }
      )
    );
  });

  it("should not complete purchase value less than total", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.01", "ether")
        }
      )
    );
  });

  it("should not complete purchase value more than total", async () => {
    await truffleAssert.reverts(
      __contract.purchaseTickets(
        __lastEvent,
        1,
        "BILETO-EVENT-1-PURCHASE-1",
        new Date().getTime(),
        "BILETO-CUSTOMER-1",
        {
          from: __customer1,
          value: web3.utils.toWei("0.11", "ether")
        }
      )
    );
  });

  it("should complete 1st purchase", async () => {
    const _result = await __contract.purchaseTickets(
      __lastEvent,
      1,
      "BILETO-EVENT-1-PURCHASE-1",
      __timestamp,
      "BILETO-CUSTOMER-1",
      {
        from: __customer1,
        value: web3.utils.toWei("0.1", "ether")
      }
    );
    const _purchaseId = await __contract.purchasesCounter();
    const _info = await __contract.fetchPurchaseInfo.call(_purchaseId);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      0,
      "purchase status is not PurchaseStatus.Completed (0)"
    );
    truffleAssert.eventEmitted(_result, "PurchaseCompleted");
  });

  it("should store purchase info accordingly", async () => {
    const _info = await __contract.fetchPurchaseInfo.call(__lastPurchase);
    const _hash1 = web3.utils.keccak256("BILETO-EVENT-1-PURCHASE-1");
    const _hash2 = web3.utils.keccak256("BILETO-CUSTOMER-1");
    assert.strictEqual(
      _info._purchaseStatus.toString(),
      "0",
      "purchase status is not PurchaseStatus.Completed (0)"
    );
    assert.strictEqual(
      _info._externalId,
      _hash1,
      "purchase external ID hash is incorrect"
    );
    assert.strictEqual(
      _info._timestamp.toString(),
      __timestamp.toString(),
      "purchase timestamp is incorrect"
    );
    assert.strictEqual(
      _info._customer,
      __customer1,
      "customer address is incorrect"
    );
    assert.strictEqual(
      _info._customerId,
      _hash2,
      "customer external ID hash is incorrect"
    );
    assert.strictEqual(
      _info._quantity.toString(),
      "1",
      "quantity of tickets purchased is incorrect"
    );
    assert.strictEqual(
      _info._total.toString(),
      web3.utils.toWei("0.1", "ether"),
      "event ticket price is incorrect"
    );
    assert.strictEqual(
      _info._eventId.toString(),
      __lastEvent.toString(),
      "event ID is incorrect"
    );
  });

  it("should cancel a purchase", async () => {
    const _result = await __contract.cancelPurchase(
      __lastPurchase,
      "BILETO-EVENT-1-PURCHASE-1",
      "BILETO-CUSTOMER-1",
      {
        from: __customer1
      }
    );
    const _info = await __contract.fetchPurchaseInfo.call(__lastPurchase);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      1,
      "purchase status is not PurchaseStatus.Cancelled (1)"
    );
    truffleAssert.eventEmitted(_result, "PurchaseCancelled");
  });

  it("should suspend ticket sales of an event", async () => {
    const _result = await __contract.suspendTicketSales(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      2,
      "event status is not EventStatus.SalesSuspended (2)"
    );
    truffleAssert.eventEmitted(_result, "EventSalesSuspended");
  });

  it("should refund a cancelled purchase", async () => {
    const _result = await __contract.refundPurchase(
      __lastEvent,
      __lastPurchase,
      {
        from: __organizer1
      }
    );
    const _info = await __contract.fetchPurchaseInfo.call(__lastPurchase);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      2,
      "purchase status is not PurchaseStatus.Refunded (2)"
    );
    truffleAssert.eventEmitted(_result, "PurchaseRefunded");
  });

  it("should start ticket sales of a suspended event", async () => {
    const _result = await __contract.startTicketSales(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      1,
      "event status is not EventStatus.SalesStarted (1)"
    );
    truffleAssert.eventEmitted(_result, "EventSalesStarted");
  });

  it("should complete 2nd purchase", async () => {
    const _result = await __contract.purchaseTickets(
      __lastEvent,
      3,
      "BILETO-EVENT-1-PURCHASE-2",
      __timestamp,
      "BILETO-CUSTOMER-1",
      {
        from: __customer1,
        value: web3.utils.toWei("0.3", "ether")
      }
    );
    const _purchaseId = await __contract.purchasesCounter();
    const _info = await __contract.fetchPurchaseInfo.call(_purchaseId);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      0,
      "purchase status is not PurchaseStatus.Completed (0)"
    );
    truffleAssert.eventEmitted(_result, "PurchaseCompleted");
  });

  it("should complete 3rd purchase", async () => {
    const _result = await __contract.purchaseTickets(
      __lastEvent,
      2,
      "BILETO-EVENT-1-PURCHASE-3",
      __timestamp,
      "BILETO-CUSTOMER-1",
      {
        from: __customer1,
        value: web3.utils.toWei("0.2", "ether")
      }
    );
    const _purchaseId = await __contract.purchasesCounter();
    const _info = await __contract.fetchPurchaseInfo.call(_purchaseId);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      0,
      "purchase status is not PurchaseStatus.Completed (0)"
    );
    truffleAssert.eventEmitted(_result, "PurchaseCompleted");
  });

  it("should end ticket sales of an event", async () => {
    const _result = await __contract.endTicketSales(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      3,
      "event status is not EventStatus.SalesFinished (3)"
    );
    truffleAssert.eventEmitted(_result, "EventSalesFinished");
  });

  it("should not check-in invalid customer", async () => {
    await truffleAssert.reverts(
      __contract.checkIn(__lastPurchase, {
        from: __organizer1
      })
    );
  });

  it("should not check-in invalid purchase", async () => {
    await truffleAssert.reverts(
      __contract.checkIn(100, {
        from: __customer1
      })
    );
  });

  it("should check-in customer", async () => {
    const _result = await __contract.checkIn(__lastPurchase, {
      from: __customer1
    });
    const _info = await __contract.fetchPurchaseInfo.call(__lastPurchase);
    assert.strictEqual(
      _info._purchaseStatus.toNumber(),
      3,
      "purchase status is not PurchaseStatus.CheckedIn (3)"
    );
    truffleAssert.eventEmitted(_result, "CustomerCheckedIn");
  });

  it("should complete an event", async () => {
    const _result = await __contract.completeEvent(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      4,
      "event status is not EventStatus.Completed (4)"
    );
    truffleAssert.eventEmitted(_result, "EventCompleted");
  });

  it("should settle an event", async () => {
    const _result = await __contract.settleEvent(__lastEvent);
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      5,
      "event status is not EventStatus.Settled (5)"
    );
    truffleAssert.eventEmitted(_result, "EventSettled");
  });

  it("should cancel an event", async () => {
    const _result = await __contract.cancelEvent(__lastEvent, {
      from: __organizer1
    });
    const _info = await __contract.fetchEventInfo.call(__lastEvent);
    assert.strictEqual(
      _info._eventStatus.toNumber(),
      6,
      "event status is not EventStatus.Cancelled (6)"
    );
    truffleAssert.eventEmitted(_result, "EventCancelled");
  });

  it("should not close store for non-owner", async () => {
    await truffleAssert.reverts(
      __contract.closeStore({
        from: __organizer1
      })
    );
  });

  it("should close store", async () => {
    const _result = await __contract.closeStore();
    __status = await __contract.storeStatus();
    assert.strictEqual(
      __status.toNumber(),
      3,
      "store status is not StoreStatus.Open (2)"
    );
    truffleAssert.eventEmitted(_result, "StoreClosed");
  });
});
