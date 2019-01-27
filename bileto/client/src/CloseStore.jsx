import React, { Component } from "react";

class CloseStore extends Component {
  state = { stackId: null };

  handleOnClick = _event => {
    const { Bileto } = this.props.drizzle.contracts;
    const { accounts } = this.props.drizzleState;
    const stackId = Bileto.methods.closeStore.cacheSend({
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
      <div className="card shadow text-white bg-danger text-center">
        <div className="card-body">
          <button
            type="button"
            className="btn btn-outline-light btn-lg"
            onClick={this.handleOnClick}
          >
            <strong>CLOSE</strong> store
          </button>
        </div>
        <p>
          Permanently close store, allowing only refunds. Store's settled and
          excess balances are transferred to owner.
        </p>
        <p className="font-weight-bold text-uppercase">{this.getTxStatus()}</p>
      </div>
    );
  }
}

export default CloseStore;
