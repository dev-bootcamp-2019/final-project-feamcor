import { drizzleConnect } from "drizzle-react";
import AppComponent from "./AppComponent";

const mapStateToProps = state => {
  return {
    accounts: state.accounts,
    accountBalances: state.accountBalances,
    Bileto: state.contracts.Bileto,
    drizzleStatus: state.drizzleStatus
  };
};

const AppContainer = drizzleConnect(AppComponent, mapStateToProps);

export default AppContainer;
