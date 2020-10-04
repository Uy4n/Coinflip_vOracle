const Coinflip_vOracle = artifacts.require("Coinflip_vOracle");
const truffleAssert = require("truffle-assertions");
// npm install truffle-assertions in the file to use

contract ("Coinflip_vOracle", async function(accounts){
    let instance;
  before(async function(){
    instance = await Coinflip_vOracle.deployed();
  });


// WARNING: none of these tests have been tried yet!
  it("shouldn't be able to flip to anything other than heads or tails", async function(){
    await instance.flipCoin(0, {value: web3.utils.toWei("0.02", "ether")});
    randomResult = instance.random();
    truffleAssert.passes(randomResult == 0 || randomResult == 1, "The coin flips to something other than heads or tails");
    await instance.flipCoin(1, {value: web3.utils.toWei("0.02", "ether")});
    randomResult = instance.random();
    truffleAssert.passes(randomResult == 0 || randomResult == 1, "The coin flips to something other than heads or tails");
  });
  it("should be able to bet on heads", async function(){
    await truffleAssert.passes(instance.flipCoin(1, {value: web3.utils.toWei("0.02", "ether")}));
  });
  it("should be able to bet on tails", async function(){
    await truffleAssert.passes(instance.flipCoin(0, {value: web3.utils.toWei("0.02", "ether")}));
  });
  it("shouldn't be able to bet on anything other than heads or tails", async function(){
    await truffleAssert.fails(instance.flipCoin(2, {value: web3.utils.toWei("0.02", "ether")}));
  });

  it("should pay the better if they win", async function(){
    previousBalance = await instance.getContractBalance();
    currentBalance = await instance.getContractBalance();
    while (currentBalance >= previousBalance){
      previousBalance = await instance.getContractBalance();
      await instance.flipCoin(1, {value: web3.utils.toWei("0.02", "ether")});
      currentBalance = await instance.getContractBalance();
    }
    await truffleAssert.passes(currentBalance <= previousBalance);
  });

  it("should let the owner of the contract withdraw its balance", async function(){
      await truffleAssert.passes(instance.withdrawFunds(1, {from: accounts[0]}), truffleAssert.ErrorType.REVERT);
    });

  it("shouldn't let anyone except the owner of the contract withdraw its balance", async function(){
      await truffleAssert.fails(instance.withdrawFunds(1, {from: accounts[1]}), truffleAssert.ErrorType.REVERT);
    });

})
