var web3 = new Web3(Web3.givenProvider);
var contractInstance;

//Type in command prompt: python -m http.server
//Type in web browser: localhost:8000
//Connect Metamask in web browser to local host (port 7545)

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      // contract address has to be changed here every time you migrate on truffle
      contractInstance = new web3.eth.Contract(abi, "0x1f8483e8721ef4D7324872cEd307b4996Acc9316", {from: accounts[0]});
      console.log(contractInstance)
    });
    $("#heads_button").click(headsInput)
    $("#tails_button").click(tailsInput)
    $("#top_up_button").click(topUpInput)
    $("#get_contract_balance_button").click(getContractBalanceOutput)
    $("#withdraw_funds_button").click(withdrawFundsOutput)

});

//Neither heads or tails has any error message for when you bet too much vs. the contract's value
//add more functionality (messages, notifications)
function headsInput(bet){
    var bet = $("#bet_input").val();
    var config = {
      value: web3.utils.toWei(bet, "ether")
    }

    contractInstance.methods.flipCoin(1).send(config)
    .on("transactionHash", function(hash){
      console.log(hash);
    })
    .on("confirmation", function(confirmationNr){
      console.log(confirmationNr);
    })
    .on("receipt", function(receipt){
      console.log(receipt);
    })
}

//Can clean up repetitive nature of the code in next project
function tailsInput(){
  var bet = $("#bet_input").val();
  var config = {
    value: web3.utils.toWei(bet, "ether")
  }

  contractInstance.methods.flipCoin(0).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
    console.log(receipt);
  })

}

function withdrawFundsOutput(balanceToTransfer){
  var balanceToTransfer = $("#withdraw_funds_output").val();
  balanceToTransfer = web3.utils.toWei(balanceToTransfer, "ether");
  //$("#withdraw_funds_output").text(balanceToTransfer + " Wei");
  //console.log(web3.utils.fromWei(balanceToTransfer, 'ether') + " ETH");

  contractInstance.methods.withdrawFunds(balanceToTransfer).send()
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
    console.log(receipt);
    alert("Withdrawal Successful!");
  })
}

function topUpInput(){
  var top_up = $("#top_up_input").val();
  var config = {
    value: web3.utils.toWei(top_up.toString(), "ether"),
    gas: 100000
  }

  contractInstance.methods.topUpContract().send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
    console.log(receipt);
    alert("Thank you for your generosity!");
    //$("#top_up_output").text(contractInstance.methods.withdrawFunds.returnString);
  })
}

//works! 01/09/2020 (careful with contract address above (in main.js))
function getContractBalanceOutput(){
  contractInstance.methods.getContractBalance().call().then(function(res){
    $("#balance_output").text(web3.utils.fromWei(res, 'ether') + " ETH");
    console.log(web3.utils.fromWei(res, 'ether') + " ETH");
  })
}
