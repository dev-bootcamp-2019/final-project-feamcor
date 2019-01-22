import AppComponent from "./AppComponent";
import { drizzleConnect } from "drizzle-react";

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
