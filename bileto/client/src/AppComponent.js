import React, { Component } from "react";
import {
  AccountData,
  ContractData,
  ContractForm
} from "drizzle-react-components";
import PropTypes from "prop-types";
import logo from "./tickets.png";

class AppComponent extends Component {
  render() {
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
              <small>
                &nbsp;&nbsp;&nbsp;
                {this.context.drizzle.contracts.Bileto.address}
              </small>
            </div>
          </span>
        </nav>
        <div className="container">
          <div className="row mt-3">
            <div className="col">
              <div className="card shadow text-white bg-primary">
                <h5 className="card-header">Account</h5>
                <div className="card-body">
                  <AccountData
                    contract="Bileto"
                    accountIndex="0"
                    units="ether"
                  />
                </div>
              </div>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-8">
              <div className="card shadow h-100">
                <h5 className="card-header">Store</h5>
                <div className="card-body">
                  <ContractData contract="Bileto" method="fetchStoreInfo" />
                </div>
              </div>
            </div>
            <div className="col-4">
              <div className="row">
                <div className="col">
                  <div className="card shadow text-white bg-primary">
                    <h5 className="card-header">Account Role</h5>
                    <div className="card-body">
                      <ContractData
                        contract="Bileto"
                        method="getAccountRole"
                        methodArgs={[this.props.accounts[0]]}
                      />
                    </div>
                  </div>
                </div>
              </div>
              <div className="row mt-3">
                <div className="col">
                  <div className="card shadow border-info">
                    <h5 className="card-header">Store Status</h5>
                    <ul className="list-group list-group-flush">
                      <li className="card-text list-group-item">0 - Created</li>
                      <li className="list-group-item">1 - Open</li>
                      <li className="list-group-item">2 - Suspended</li>
                      <li className="list-group-item">3 - Closed</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-md-4">
              <div className="card shadow text-white bg-success h-100">
                <h5 className="card-header">Open Store</h5>
                <div className="card-body">
                  <p className="card-text">
                    Enable store to manage all events and ticket purchases.
                  </p>
                  <ContractForm contract="Bileto" method="openStore" />
                </div>
              </div>
            </div>
            <div className="col-md-4">
              <div className="card shadow text-white bg-warning h-100">
                <h5 className="card-header">Suspend Store</h5>
                <div className="card-body">
                  <p className="card-text">
                    Temporarily disable store to manage all events and ticket
                    purchases.
                  </p>
                  <ContractForm contract="Bileto" method="suspendStore" />
                </div>
              </div>
            </div>
            <div className="col-md-4">
              <div className="card shadow text-white bg-danger h-100">
                <h5 className="card-header">Close Store</h5>
                <div className="card-body">
                  <p className="card-text">Disable store (cannot be reopen).</p>
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
