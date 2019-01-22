import React, { Component } from "react";
import PropTypes from "prop-types";
import "bootstrap/dist/css/bootstrap.css";
import AppNavBar from "./AppNavBar";
import StoreCard from "./StoreCard";
import OpenStoreCard from "./OpenStoreCard";
import SuspendStoreCard from "./SuspendStoreCard";
import CloseStoreCard from "./CloseStoreCard";
import AccountCard from "./AccountCard";

class AppComponent extends Component {
  render() {
    const { accounts, accountBalances, drizzleStatus } = this.props;
    const { web3, contracts } = this.context.drizzle;
    return (
      <React.Fragment>
        <AppNavBar contracts={contracts} />
        <div className="container">
          <div className="row mt-3">
            <div className="col-6">
              <StoreCard />
            </div>
            <div className="col-6">
              <AccountCard
                accounts={accounts}
                accountBalances={accountBalances}
                drizzleStatus={drizzleStatus}
                web3={web3}
              />
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-md-4">
              <OpenStoreCard />
            </div>
            <div className="col-md-4">
              <SuspendStoreCard />
            </div>
            <div className="col-md-4">
              <CloseStoreCard />
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
