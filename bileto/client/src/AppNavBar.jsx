import React, { Component } from "react";
import logo from "./tickets.png";

class AppNavBar extends Component {
  render() {
    const { contracts } = this.props;
    return (
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
            <small>&nbsp;&nbsp;&nbsp;{contracts.Bileto.address}</small>
          </div>
        </span>
      </nav>
    );
  }
}

export default AppNavBar;
