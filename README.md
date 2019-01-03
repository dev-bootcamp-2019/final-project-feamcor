# Bileto

[Bileto](https://en.wiktionary.org/wiki/bileto) is a simple decentralized online ticket store on Ethereum.

- [Bileto](#bileto)
  - [Introduction](#introduction)
  - [High-level Solution](#high-level-solution)
  - [Set-up](#set-up)
  - [Enhancements](#enhancements)
  - [Project Specifications](#project-specifications)
  - [Project Requirements](#project-requirements)

## Introduction
__Bileto__ is a standalone smart contract which implements the business of a simple online ticket store.

It is written in [Solidity](https://solidity.readthedocs.io/en/v0.5.2/index.html) and compiled using `solc` version [0.5.2](https://github.com/ethereum/solidity/releases/tag/v0.5.2).

It can be deployed to an [Ethereum](https://ethereum.org) blockchain, be it the public [mainnet](https://etherscan.io), a public testnet like [Rinkeby](https://rinkeby.etherscan.io), a private blockchain, or on a local development blockchain like [Ganache](https://truffleframework.com/ganache).

As currency for ticket purchases, it uses Ethereum's native [Ether](https://www.ethereum.org/ether).

__Bileto__ was developed as [my](https://github.com/feamcor) final project for the [ConsenSys Academy Developer Program Bootcamp](https://consensys.net/academy/bootcamp), cohort of [October 29th, 2018](https://courses.consensys.net/courses/course-v1:ConsenSysAcademy+2018DP+2/about), and it also provides a simple [web3](https://blockchainhub.net/web3-decentralized-web)-enabled web application ([DApp](https://ethereum.stackexchange.com/questions/383/what-is-a-dapp)) for trying its functionalities.

## High-level Solution
The __Bileto__ contract manages a few entities:
- __Store__ - one per deployed contract. A store has an owner which in essence is the [EOA](https://ethereum.stackexchange.com/questions/5828/what-is-an-eoa-account) who deployed the contract. Only the owner can withdraw store's funds. Only owner can open, suspend ([circuit breaker](https://github.com/ConsenSys/smart-contract-best-practices/blob/master/docs/software_engineering.md#circuit-breakers-pause-contract-functionality)) and close the store. Closing a store is a final status that cannot be reversed. A store cannot be closed while there are pending refundable balance (to be paid back to customers due to purchase or event cancellations); 
- __Event__ - many events can be created per store. An event has an organizer which is an EOA set during event creation. Event organizer will receive (withdraw) event's funds when event is completed. Organizer can start, suspend (circuit breaker) or finish ticket sales for his/her event. Organizer can also cancel the event;
- __Purchase__ - many purchases can be performed per event (limited to the quantity of tickets available for sale). A purchase is always related to one event. If a customer wants to buy tickets, for instance, of two distinct events, he/she has to perform, at least, two purchases, one for each event. Customer can purchase one or more tickets on a single purchase. A purchase can be cancelled by customer while event is not completed, or by organizer when an event is cancelled. These cancellations give the right to the customer to be refunded (has to be requested by customer only).

A __check-in__ status is set when customer actually attends to the event, making use of the tickets that he/she purchased previously. 

The diagram below depicts the state transition and main pre-conditions handled by the contract for its entities.

![Bileto State Diagram](bileto_state_diagram.svg)

## Set-up
The source code of Bileto can be found at [GitHub](https://github.com/dev-bootcamp-2019/final-project-feamcor).

## Enhancements
A list of possible enhancements for this contract are:
- Allow different kinds of tickets, with distinct prices.
- Allow multiple accounts to manage the store.
- Allow multiple accounts to manage an event.
- Allow store balance to be distributed to many accounts.
- Allow event balance to be distributed to many accounts.
- Split contract in two:
  - _BiletoStore_ - to be deployed once;
  - _BiletoEvent_ - to be deployed when an event is created.
- Replace store currency from Ether to a utility token.
- Integrate customer identification with UPort or other sovereign identity provider.
- _etc._

---

## Project Specifications
- [x] A README.md that explains the project
  - [x] What does it do?
  - [ ] How to set it up.
    - [ ] How to run a local development server.
- [x] It should be a [Truffle project](https://truffleframework.com/docs/truffle/getting-started/creating-a-project).
  - [x] All contracts should be in a `contracts` directory.
    - [x] `truffle compile` should successfully compile contracts.
  - [x] Migration contract and migration scripts should work.
    - [x] `truffle migrate` should successfully migrate contracts to a locally running `ganache-cli` test blockchain on port `8454`.
  - [x] All tests should be in a `tests` directory.
    - [x] `truffle test` should migrate contracts and run the tests.
- [x] Smart contract code should be commented according to the [specs in the documentation](https://solidity.readthedocs.io/en/v0.5.2/layout-of-source-files.html#comments).
- [x] Create at least 5 tests for each smart contract.
  - [ ] Write a sentence or two explaining what the tests are covering, and explain why those tests were written.
- [ ] A development server to serve the front-end interface of the application.
  - [ ] It can be something as simple as the [lite-server](https://www.npmjs.com/package/lite-server) used in the [Truffle Pet Shop tutorial](https://truffleframework.com/tutorials/pet-shop).
- [ ] A document [design_pattern_decisions.md](design_pattern_decisions.md) that explains the design patterns chosen.
- [ ] A document [avoiding_common_attacks.md](avoiding_common_attacks.md) that explains what measures were taken to ensure that the contracts are not susceptible to common attacks.
- [x] Implement/use a library or an EthPM package.
  - [ ] If the project does not require a library or an EthPM package, demonstrate how it would do that in a contract called `LibraryDemo.sol`.
- [ ] Develop your application and run the other projects during evaluation in a VirtualBox VM running Ubuntu 16.04 to reduce the chances of runtime environment variables.

## Project Requirements

### User Interface
- [ ] Run the dapp on a development server locally for testing and grading.
- [ ] You should be able to visit a URL and interact with the application:
  - [ ] App recognizes current account;
  - [ ] Sign transactions using MetaMask or uPort;
  - [ ] Contract state is updated;
  - [ ] Update reflected in UI.

### Testing
- [x] Write 5 tests for each contract you wrote;
  - [x] Solidity __or__ JavaScript.
- [ ] Explain why you wrote those tests;
  - [x] Tests run with `truffle test`.

### Design Patterns
- [x] Implement a circuit breaker (emergency stop) pattern.
- [ ] What other design patterns have you used / not used?
  - [ ] Why did you choose the patterns that you did?
  - [ ] Why not others?

### Security Tools / Common Attacks
- [ ] Explain what measures you have taken to ensure that your contracts are not susceptible to common attacks.

### Use a Library or Extend a Contract
- [x] Via EthPM or write your own.

### Deployment
- [ ] Deploy your application onto one of the test networks.
- [ ] Include a document called [deployed_addresses.txt](deployed_addresses.txt) that describes where your contracts live (which testnet and address).
- [ ] Students can verify their source code using Etherscan https://etherscan.io/verifyContract for the appropriate testnet.
- [ ] Evaluators can check by getting the provided contract ABI and calling a function on the deployed contract at https://www.myetherwallet.com/#contracts or checking the verification on Etherscan.

### Stretch
- [ ] Implement an upgradable design pattern.
- [ ] Write a smart contract in LLL or Vyper.
- [ ] Integrate with an additional service. For example:
  - [ ] IPFS - users can dynamically upload documents to IPFS that are referenced via their smart contract.
  - [ ] uPort
  - [ ] Ethereum Name Service - a name registered on the ENS resolves to the contract, verifiable on `https://rinkeby.etherscan.io/<contract_name>`
  - [ ] Oracle
