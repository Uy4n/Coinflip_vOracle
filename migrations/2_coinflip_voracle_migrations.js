const Coinflip_vOracle = artifacts.require("Coinflip_vOracle");
// Deploying the contract with an inital value by making a payable constructor
module.exports = function(deployer, network, accounts) {
  deployer.deploy(Coinflip_vOracle).then(function(instance){
    instance.topUpContract({value: web3.utils.toWei("12", "ether"), from: accounts[0]})
  });

};
