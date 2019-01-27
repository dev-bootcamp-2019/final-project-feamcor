import React, { Component } from "react";
import AccountInfo from "./AccountInfo";
import StoreInfo from "./StoreInfo";
import OpenStore from "./OpenStore";
import SuspendStore from "./SuspendStore";
import CloseStore from "./CloseStore";
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
            <div className="col-8">
              <AccountInfo
                drizzle={this.props.drizzle}
                drizzleState={this.state.drizzleState}
              />
            </div>
            <div className="col-4">
              <OpenStore
                drizzle={this.props.drizzle}
                drizzleState={this.state.drizzleState}
              />
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
              <div className="row mt-2">
                <div className="col">
                  <SuspendStore
                    drizzle={this.props.drizzle}
                    drizzleState={this.state.drizzleState}
                  />
                </div>
              </div>
              <div className="row mt-2">
                <div className="col">
                  <CloseStore
                    drizzle={this.props.drizzle}
                    drizzleState={this.state.drizzleState}
                  />
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
                  <form onSubmit={undefined}>
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
                            value={undefined}
                            onChange={undefined}
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
