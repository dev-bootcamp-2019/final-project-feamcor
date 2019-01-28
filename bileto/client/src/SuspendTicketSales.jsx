import React, { Component } from "react";

class SuspendTicketSales extends Component {
  state = { stackId: null };

  constructor(props) {
    super(props);
    this.handleOnClick = this.handleOnClick.bind(this);
  }

  handleOnClick = _event => {
    const { Bileto } = this.props.drizzle.contracts;
    const stackId = Bileto.methods.suspendTicketSales.cacheSend(
      this.props.eventId
    );
    this.setState({ stackId });
  };

  getTxStatus = () => {
    const { transactions, transactionStack } = this.props.drizzleState;
    const txHash = transactionStack[this.state.stackId];
    if (!txHash) return "...";
    // console.log(transactions[txHash]);
    return transactions[txHash].status;
  };

  render() {
    const { drizzleStatus, web3 } = this.props.drizzleState;
    if (!drizzleStatus.initialized || web3.status !== "initialized") {
      return "Loading...";
    }

    return (
      <div className="card shadow border-warning text-center">
        <div className="card-body">
          <button
            type="button"
            className="btn btn-warning btn-lg"
            onClick={this.handleOnClick}
          >
            <strong>SUSPEND</strong> ticket sales
          </button>
        </div>
        <span className="card-footer font-weight-bold text-uppercase">
          {this.getTxStatus()}
        </span>
      </div>
    );
  }
}

export default SuspendTicketSales;
