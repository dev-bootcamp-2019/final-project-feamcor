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
    const dataKey = Bileto.methods.getAccountRole.cacheCall(accounts[0]);
    this.setState({ dataKey });
  }

  render() {
    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

    const { accounts, accountBalances } = this.props.drizzleState;
    const { Bileto } = this.props.drizzleState.contracts;

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
      <div className="card shadow text-white bg-primary h-100">
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
            <span className="card-text">
              {accountIsOwner === true && " OWNER "}
              {accountIsOrganizer === true && " ORGANIZER "}
              {accountIsCustomer === true && " CUSTOMER "}
              {accountIsOwner === false &&
                accountIsOrganizer === false &&
                accountIsCustomer === false &&
                " NONE "}
            </span>
          </p>
        </div>
      </div>
    );
  }
}

export default AccountInfo;
