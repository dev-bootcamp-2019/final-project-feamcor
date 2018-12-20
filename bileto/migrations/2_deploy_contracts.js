var Bileto = artifacts.require("./Bileto.sol");

module.exports = function(deployer) {
  deployer.deploy(Bileto);
};
