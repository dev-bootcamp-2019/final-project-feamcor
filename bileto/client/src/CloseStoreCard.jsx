import React, { Component } from "react";
import { ContractForm } from "drizzle-react-components";
import "bootstrap/dist/css/bootstrap.css";

class CloseStoreCard extends Component {
  render() {
    return (
      <div className="card shadow text-white bg-danger h-100">
        <h5 className="card-header">Close Store</h5>
        <div className="card-body">
          <p className="card-text">Disable store (cannot be reopen).</p>
          <ContractForm contract="Bileto" method="closeStore" />
        </div>
      </div>
    );
  }
}

export default CloseStoreCard;
