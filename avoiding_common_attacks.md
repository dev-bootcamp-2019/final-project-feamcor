# ACCOUNT ROLE

- Each account who interacts with the contract has a specific role and has its actions limited by such.
- Three roles are implemented in Bileto:
  - Store owner - who deployed the Bileto smart contract to the blockchain.
  - Event organizer - who manages and own an event.
  - Customer - who purchases tickets.

# OVERFLOW PROTECTION

- Use of OpenZeppelin SafeMath library for safe operations on top of UINT256.

# REENTRANCY

- Use of OpenZeppelin Reentrancy Guard contract.

# TIMESTAMP

- Timestamp is provided by DApp but has no influence on the smart contract.

# NO USE OF LOOPS

- Fetch functions made available in order to retrieve individuals of an array or mapping.

# STATIC ANALYSIS

- Use of linters and other tools like Mythril, Solium and Solhint.
