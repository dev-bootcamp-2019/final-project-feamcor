import React, { Component } from "react";

class AccountInfo extends Component {
  formatWeiToEther(_amount) {
    let _output = !_amount
      ? "???"
      : this.props.drizzle.web3.utils.fromWei(_amount.toString(), "ether");
    _output += " ETHER";
    return _output;
  }

  render() {
    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

    const { accounts, accountBalances } = this.props.drizzleState;

    return (
      <div className="card shadow text-white bg-primary">
        <h5 className="card-header">
          <strong>ACCOUNT</strong> information
        </h5>
        <div className="card-body">
          <p className="card-text">
            <strong>Address: </strong>
            {accounts[0]}
          </p>
          <p className="card-text">
            <strong>Balance: </strong>
            {this.formatWeiToEther(accountBalances[accounts[0]])}
          </p>
        </div>
      </div>
    );
  }
}

export default AccountInfo;
