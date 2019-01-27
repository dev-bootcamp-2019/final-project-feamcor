import React, { Component } from "react";

class AccountInfo extends Component {
  state = { dataKey: null };

  formatWeiToEther(_amount) {
    let _output = !_amount
      ? "???"
      : this.props.drizzle.web3.utils.fromWei(_amount.toString(), "ether");
    _output += " ETHER";
    return _output;
  }

  componentDidMount() {
    const { Bileto } = this.props.drizzle.contracts;
    const { accounts } = this.props.drizzleState;
    const methodArgs = new Array(accounts[0]);
    const dataKey = Bileto.methods.getAccountRole.cacheCall(...methodArgs);
    this.setState({ dataKey });
  }

  render() {
    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

    const { Bileto } = this.props.drizzleState.contracts;

    const { accounts, accountBalances } = this.props.drizzleState;

    const accountRole = Bileto.getAccountRole[this.state.dataKey];
    if (!accountRole || !accountRole.value) {
      return "Loading...";
    }

    const {
      accountIsOwner,
      accountIsOrganizer,
      accountIsCustomer
    } = accountRole.value;

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
          <p className="card-text">
            <strong>Roles: </strong>
            {accountIsOwner && " OWNER "}
            {accountIsOrganizer && " ORGANIZER "}
            {accountIsCustomer && " CUSTOMER "}
            {!accountIsOwner &&
              !accountIsOrganizer &&
              !accountIsCustomer &&
              " NONE "}
          </p>
        </div>
      </div>
    );
  }
}

export default AccountInfo;
