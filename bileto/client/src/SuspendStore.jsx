import React, { Component } from "react";

class SuspendStore extends Component {
  state = { stackId: null };

  handleOnClick = _event => {
    const { Bileto } = this.props.drizzle.contracts;
    const { accounts } = this.props.drizzleState;
    const stackId = Bileto.methods.suspendStore.cacheSend({
      from: accounts[0]
    });
    this.setState({ stackId });
  };

  getTxStatus = () => {
    const { transactions, transactionStack } = this.props.drizzleState;
    const txHash = transactionStack[this.state.stackId];
    if (!txHash) return "...";
    return transactions[txHash].status;
  };

  render() {
    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

    return (
      <div className="card shadow text-white bg-warning text-center">
        <div className="card-body">
          <button
            type="button"
            className="btn btn-outline-light btn-lg"
            onClick={this.handleOnClick}
          >
            <strong>SUSPEND</strong> store
          </button>
        </div>
        <p>
          Temporarily suspend store handling of events and ticket purchases.
        </p>
        <p className="font-weight-bold text-uppercase">{this.getTxStatus()}</p>
      </div>
    );
  }
}

export default SuspendStore;
