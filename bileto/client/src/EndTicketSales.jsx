import React, { Component } from "react";

class EndTicketSales extends Component {
  state = { stackId: null, _eventId: "" };

  constructor(props) {
    super(props);
    this.handleOnChange = this.handleOnChange.bind(this);
    this.handleOnClick = this.handleOnClick.bind(this);
  }

  handleOnClick = _event => {
    const { Bileto } = this.props.drizzle.contracts;
    const { accounts } = this.props.drizzleState;
    const stackId = Bileto.methods.endTicketSales.cacheSend(
      this.state._eventId,
      { from: accounts[0] }
    );
    this.setState({ stackId });
  };

  handleOnChange = _event => {
    this.setState({ [_event.target.name]: _event.target.value });
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
      <div className="card shadow border-danger text-center">
        <div className="card-body">
          <h6>
            <strong>END</strong> ticket sales
          </h6>
          <div className="input-group">
            <div className="input-group-prepend">
              <span className="input-group-text" id="labelEventId">
                #
              </span>
            </div>
            <input
              type="number"
              key="_eventId"
              name="_eventId"
              value={this.state._eventId}
              onChange={this.handleOnChange}
              min="1"
              className="form-control"
              placeholder="Event ID"
              aria-label="Event ID"
              aria-describedby="labelEventId"
              required
            />
            <div className="input-group-append">
              <button
                type="button"
                className="btn btn-danger btn-sm"
                onClick={this.handleOnClick}
              >
                submit
              </button>
            </div>
          </div>
        </div>
        <span className="card-footer font-weight-bold text-uppercase">
          {this.getTxStatus()}
        </span>
      </div>
    );
  }
}

export default EndTicketSales;
