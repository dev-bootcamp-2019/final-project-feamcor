const Bileto = artifacts.require('Bileto')

contract('Bileto', async (accounts) => {
  let _contract;
  let _address;
  let _owner;
  let _balance;
  let _status;
  let _refundable;
  let _lastEvent;
  let _lastPurchase;

  before(async () => {
    _contract = await Bileto.deployed();
    _address = _contract.address;
    _owner = await _contract.owner();
    console.log("store address:" + _address);
    console.log("store owner: " + _owner);
  });

  beforeEach(async () => {
    _status = await _contract.storeStatus();
    _balance = await web3.eth.getBalance(_address);
    _refundable = await _contract.storeRefundableBalance();
    _lastEvent = await _contract.eventsCounter();
    _lastPurchase = await _contract.purchasesCounter();
    console.log("store status: " + _status);
    console.log("store balance: " + _balance);
    console.log("store refundable: " + _refundable);
    console.log("last event: " + _lastEvent);
    console.log("last purchase: " + _lastPurchase);
  });

  it("should create store", async () => {
    assert.strictEqual(_status.toNumber(), 0, "store status is not StoreStatus.Created (0)");
    assert.strictEqual(_balance, '0', "store balance is not zero");
    assert.strictEqual(_refundable.toNumber(), 0, "store refundable balance is not zero");
  });

  it("should open store", async () => {
    let _result = await _contract.openStore();
    _status = await _contract.storeStatus();
    console.log("emitted event: " + _result.logs[0].event);
    assert.strictEqual(_status.toNumber(), 1, "store status is not StoreStatus.Open (1)");
  });

  it("should suspend store", async () => {
    let _result = await _contract.suspendStore();
    _status = await _contract.storeStatus();
    console.log("emitted event: " + _result.logs[0].event);
    assert.strictEqual(_status.toNumber(), 2, "store status is not StoreStatus.Open (2)");
  });

  it("should close store", async () => {
    let _result = await _contract.closeStore();
    _status = await _contract.storeStatus();
    console.log("emitted event: " + _result.logs[0].event);
    assert.strictEqual(_status.toNumber(), 3, "store status is not StoreStatus.Open (2)");
  });
});
