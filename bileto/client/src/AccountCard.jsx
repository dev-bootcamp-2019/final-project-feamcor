import React, { Component } from "react";

class AccountCard extends Component {
  getAccountRole() {
    let role = "???";
    return role;
  }

  getAccountBalance() {
    const { accounts, accountBalances, drizzleStatus, web3 } = this.props;
    let balance = "0";
    if (drizzleStatus.initialized) {
      balance = web3.utils.fromWei(accountBalances[accounts[0]], "ether");
    }
    return balance + " ether";
  }

  render() {
    const { accounts } = this.props;
    return (
      <div className="card shadow">
        <h5 className="card-header">Active Account</h5>
        <div className="card-body">
          <p className="card-text text-right">{accounts[0]}</p>
          <p className="card-text text-right">
            <strong>Balance: </strong>
            {this.getAccountBalance()}
          </p>
          <button type="button" className="btn btn-info">
            Role{" "}
            <span className="badge badge-light">{this.getAccountRole()}</span>
          </button>
        </div>
      </div>
    );
  }
}

export default AccountCard;
