import React, { Component } from "react";
import { ContractForm } from "drizzle-react-components";

class SuspendStoreCard extends Component {
  render() {
    return (
      <div className="card shadow text-white bg-warning h-100">
        <h5 className="card-header">Suspend Store</h5>
        <div className="card-body">
          <p className="card-text">
            Temporarily disable store to manage all events and ticket purchases.
          </p>
          <ContractForm contract="Bileto" method="suspendStore" />
        </div>
      </div>
    );
  }
}

export default SuspendStoreCard;
