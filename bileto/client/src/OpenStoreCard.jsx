import React, { Component } from "react";
import { ContractForm } from "drizzle-react-components";

class OpenStoreCard extends Component {
  render() {
    return (
      <div className="card shadow text-white bg-success h-100">
        <h5 className="card-header">Open Store</h5>
        <div className="card-body">
          <p className="card-text">
            Enable store to manage all events and ticket purchases.
          </p>
          <ContractForm contract="Bileto" method="openStore" />
        </div>
      </div>
    );
  }
}

export default OpenStoreCard;
