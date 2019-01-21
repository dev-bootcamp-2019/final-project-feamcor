import Bileto from "./contracts/Bileto.json";

const options = {
  web3: {
    block: false,
    fallback: {
      type: "ws",
      url: "ws://127.0.0.1:7545" // Ganache GUI
      // url: "ws://127.0.0.1:8545" // Ganache CLI
      // url: "ws://127.0.0.1:9545" // Truffle Develop
    }
  },
  contracts: [Bileto],
  events: {
    Bileto: [
      "OwnershipTransferred",
      "StoreOpen",
      "StoreSuspended",
      "StoreClosed",
      "EventCreated",
      "EventSalesStarted",
      "EventSalesSuspended",
      "EventSalesFinished",
      "EventCompleted",
      "EventSettled",
      "EventCancelled",
      "PurchaseCompleted",
      "PurchaseCancelled",
      "PurchaseRefunded",
      "CustomerCheckedIn"
    ]
  },
  polls: {
    accounts: 1500,
    blocks: 3000
  },
  syncAlways: false
};

export default options;
