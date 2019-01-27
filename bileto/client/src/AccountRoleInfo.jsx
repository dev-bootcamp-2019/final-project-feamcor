import React, { Component } from "react";

class AccountRoleInfo extends Component {
  state = { dataKey: null };

  componentDidMount() {
    const { Bileto } = this.props.drizzle.contracts;
    const { accounts } = this.props.drizzleState;
    const methodArgs = new Array(accounts[0]);
    const dataKey = Bileto.methods.getAccountRole.cacheCall(...methodArgs);
    this.setState({ dataKey });
  }

  render() {
    const { Bileto } = this.props.drizzleState.contracts;

    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

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
          <strong>ACCOUNT</strong> role
        </h5>
        <div className="card-body">
          <p className="card-text text-center">
            <strong>{accountIsOwner && " OWNER "}</strong>
            <strong>{accountIsOrganizer && " ORGANIZER "}</strong>
            <strong>{accountIsCustomer && " CUSTOMER "}</strong>
            <strong>
              {!accountIsOwner &&
                !accountIsOrganizer &&
                !accountIsCustomer &&
                " NONE "}
            </strong>
          </p>
        </div>
      </div>
    );
  }
}

export default AccountRoleInfo;
