import React, { Component } from "react";
import PropTypes from "prop-types";
import {
  AccountData,
  ContractData,
  ContractForm
} from "drizzle-react-components";

import "bootstrap/dist/css/bootstrap.css";
import logo from "./tickets.png";

class AppComponent extends Component {
  constructor(props, context) {
    super(props);
  }

  render() {
    const { accounts, accountBalances } = this.props;
    const { web3, contracts } = this.context.drizzle;
    return (
      <React.Fragment>
        <nav className="navbar sticky-top navbar-dark bg-dark">
          <span className="navbar-brand">
            <img
              src={logo}
              width="64"
              height="64"
              className="d-inline-block align-middle"
              alt="bileto-logo"
            />
            <strong> Bileto </strong>a simple ticket store on Ethereum
            <div className="navbar-text text-muted">
              <small>&nbsp;&nbsp;&nbsp;{contracts.Bileto.address}</small>
            </div>
          </span>
        </nav>

        <div className="container">
          <div className="row mt-3">
            <div className="col-6">
              <div className="card shadow">
                <h5 className="card-header">Store</h5>
                <div className="card-body">
                  <ContractData contract="Bileto" method="fetchStoreInfo" />
                </div>
              </div>
            </div>
            <div className="col-6">
              <div className="card shadow">
                <h5 className="card-header">Active Account</h5>
                <div className="card-body">
                  <p className="card-text text-right">{accounts[0]}</p>
                  <p className="card-text text-right">
                    <strong>Balance: </strong>
                    {web3.utils.fromWei(accountBalances[accounts[0]], "ether")}
                    {" ether"}
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-md-4">
              <div className="card text-white bg-success h-100">
                <h5 className="card-header">Open Store</h5>
                <div className="card-body">
                  <p className="card-text">
                    Enable store to manage all events and ticket purchases
                  </p>
                  <ContractForm contract="Bileto" method="openStore" />
                </div>
              </div>
            </div>
            <div className="col-md-4">
              <div className="card text-white bg-warning h-100">
                <h5 className="card-header">Suspend Store</h5>
                <div className="card-body">
                  <p className="card-text">
                    Temporarily disable store to manage all events and ticket
                    purchases
                  </p>
                  <ContractForm contract="Bileto" method="suspendStore" />
                </div>
              </div>
            </div>
            <div className="col-md-4">
              <div className="card text-white bg-danger h-100">
                <h5 className="card-header">Close Store</h5>
                <div className="card-body">
                  <p className="card-text">Disable store (cannot be reopen)</p>
                  <ContractForm contract="Bileto" method="closeStore" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

AppComponent.contextTypes = {
  drizzle: PropTypes.object
};

export default AppComponent;
