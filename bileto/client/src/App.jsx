import React, { Component } from "react";
import StoreInfo from "./StoreInfo";
import logo from "./tickets.png";

class App extends Component {
  state = { loading: true, drizzleState: null };

  componentDidMount() {
    const { drizzle } = this.props;

    this.unsubscribe = drizzle.store.subscribe(() => {
      const drizzleState = drizzle.store.getState();
      if (drizzleState.drizzleStatus.initialized) {
        this.setState({ loading: false, drizzleState });
      }
    });
  }

  componentWillUnmount() {
    this.unsubscribe();
  }

  render() {
    if (this.state.loading) return "Loading...";
    return (
      <React.Fragment>
        <nav className="navbar sticky-top navbar-dark bg-dark">
          <span className="navbar-brand">
            <img
              src={logo}
              width="64"
              height="64"
              className="d-inline-block align-middle"
              alt="bileto-logo"
            />
            <strong> Bileto </strong>a simple ticket store on Ethereum
            <div className="navbar-text text-muted">
              <small>
                &nbsp;&nbsp;&nbsp;
                {this.props.drizzle.contracts.Bileto.address}
              </small>
            </div>
          </span>
        </nav>
        <div className="container">
          <div className="row mt-3">
            <div className="col-12">
              <div className="card shadow text-white bg-primary">
                <h5 className="card-header">Account</h5>
                <div className="card-body">AccountInfo</div>
              </div>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-8">
              <StoreInfo
                drizzle={this.props.drizzle}
                drizzleState={this.state.drizzleState}
              />
            </div>
            <div className="col-4">
              <div className="row">
                <div className="col">
                  <div className="card shadow text-white bg-success h-100">
                    <h5 className="card-header">Open Store</h5>
                    <div className="card-body">
                      <p className="card-text">
                        Enable store to manage events and ticket purchases.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="row mt-3">
                <div className="col">
                  <div className="card shadow text-white bg-warning h-100">
                    <h5 className="card-header">Suspend Store</h5>
                    <div className="card-body">
                      <p className="card-text">
                        Temporarily disable store, stopping events and ticket
                        purchases.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="row mt-3">
                <div className="col">
                  <div className="card shadow text-white bg-danger h-100">
                    <h5 className="card-header">Close Store</h5>
                    <div className="card-body">
                      <p className="card-text">
                        Permanently disable store, allowing only refunds.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="row mt-3">
            <div className="col-md-4">
              <div className="card shadow">
                <h5 className="card-header">Create Event</h5>
                <div className="card-body">CreateEvent </div>
              </div>
            </div>
            <div className="col-md-8">
              <div className="card shadow">
                <div className="card-header">
                  <form onSubmit={console.log("onSubmit")}>
                    <div className="form-row align-items-center">
                      <div className="col-auto">
                        <h5>Event</h5>
                      </div>
                      <div className="col-auto">
                        <label className="sr-only" htmlFor="fetchEventInfo">
                          Event ID
                        </label>
                        <div className="input-group mb-2">
                          <input
                            type="text"
                            className="form-control"
                            value={console.log("value")}
                            onChange={console.log("onChange")}
                            id="fetchEventInfo"
                            placeholder="Event ID"
                          />
                        </div>
                      </div>
                      <div className="col-auto">
                        <button type="submit" className="btn btn-primary mb-2">
                          Fetch
                        </button>
                      </div>
                    </div>
                  </form>
                </div>
                <div className="card-body">FetchEventInfo </div>
              </div>
            </div>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default App;
