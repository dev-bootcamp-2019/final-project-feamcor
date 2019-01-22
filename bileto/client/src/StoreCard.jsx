import React, { Component } from "react";
import { ContractData } from "drizzle-react-components";
import "bootstrap/dist/css/bootstrap.css";

class StoreCard extends Component {
  render() {
    return (
      <div className="card shadow">
        <h5 className="card-header">Store</h5>
        <div className="card-body">
          <ContractData contract="Bileto" method="fetchStoreInfo" />
        </div>
      </div>
    );
  }
}

export default StoreCard;
