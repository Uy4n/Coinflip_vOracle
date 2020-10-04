const Selfdestructable = artifacts.require("Selfdestructable");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Selfdestructable);
};
