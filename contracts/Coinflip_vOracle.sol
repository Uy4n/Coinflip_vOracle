// SPDX-License-Identifier: UNLICENSED;
import"./Ownable.sol";
import"./Selfdestructable.sol";
import "./provableAPI.sol";
pragma solidity >= 0.5.16 <0.7.0;

contract Coinflip_vOracle is Ownable, Selfdestructable, usingProvable{

    uint public balance;

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
    uint256 public latestNumber; //from lesson 3/8

    string[] public messages = ["You lost...", "You won!"];

    struct Player {
        address payable playerAddress;
        uint betAmount;
        bool headsOrTails; //true = heads, false = tails
        uint playerBalance;
    }

    /*
    constructor()
        public
    {
        //21/09/20 these constructors don't currently work in remix.eth
        provable_setCustomGasPrice(80000000000);
        provable_setProof(proofType_Ledger);
        update();
    }
    */

    mapping (address => Player) private playersId;
    mapping (bytes32 => bool) private isWaiting; // true = can't open another game, false = can open a game
    mapping (bytes32 => Player) private players;

    event FlipResult (string message, address playerAddress, bytes32 queryId);
    event WithdrawComplete (address owner, uint balanceToTransfer);
    // Uncomment the LogNewProvableQuery line once ready to deploy on Ropsten
    event LogNewProvableQuery (string description);
    event provableQuerySent(string message, address creator);
    event GeneratedRandomNumber (uint256 randomNumber);

    modifier costs(uint cost)
    {
        require(msg.value >= cost, "You must bet at least 0.01 ether");
        _;
    }

    modifier lessThanBalance(uint value)
    {
        //require(balance >= 0);
        require(2 * msg.value < value, "Your bet is higher than this contract's value!");
        _;
    }

    function createBet(bytes32 queryId, address payable playerAddress, uint betAmount, bool headsOrTails)
        public
    {
        Player memory bet;
        bet.playerAddress = playerAddress;
        bet.betAmount = betAmount;
        bet.headsOrTails = headsOrTails;
        isWaiting[queryId] = true;
        playersId[msg.sender] = bet;
    }

    // Make the player able to play as much as they want, then withdraw ALL AT
    // ONCE, once they are finished playing the game

    function flipCoin(uint betValue, bool headsOrTails)
        public
        payable
        costs(0.01 ether)
        lessThanBalance(balance)
    {
        // intialize the player's queryId
        bytes32 queryId;

        //callOracle();
        testRandom();

        createBet(queryId, msg.sender, betValue, headsOrTails);
    }

    function callOracle()
        payable
        public
        returns(bytes32)
    {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        bytes32 queryId = provable_newRandomDSQuery
        (
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );
        emit LogNewProvableQuery("Provable query was sent, standing by for callback...");
        return queryId;
    }

    // use when you want to test, but also want to avoid testnet delays
    function testRandom()
        public
        returns(bytes32)
    {
        bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
        __callback(queryId, "1", bytes("test"));
        emit provableQuerySent("Test queried", msg.sender);
        return queryId;
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof)
        public
        override
    {
        //Only the oracle should be able to call this function
        require(msg.sender == provable_cbAddress());

        if (
            provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        )
        {
            isWaiting[_queryId] = false;
            revert();
        }
        else
        {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
            resultFlipCoin(_queryId, randomNumber);
        }
    }

    function resultFlipCoin(bytes32 _queryId, uint256 randomNumber)
        private
    {
        latestNumber = randomNumber;
        emit GeneratedRandomNumber(latestNumber);

        string memory message;

        bool boolRandomNumber;
        if(randomNumber == 1)
        {
            boolRandomNumber = true;
        }
        else if(randomNumber == 0)
        {
            boolRandomNumber = false;
        }
        else
        {
            assert(false);
        }

        uint betValue = players[_queryId].betAmount;
        bool headsOrTails = players[_queryId].headsOrTails;

        if(headsOrTails == boolRandomNumber)
        {
            message = "You won!";
            players[_queryId].playerBalance += 2 * betValue;
            balance -= 2 * betValue;
        }
        else
        {
            message = "You lost...";
            players[_queryId].playerBalance -= betValue;
            balance += betValue;
            if(players[_queryId].playerBalance < 0)
            {
               players[_queryId].playerBalance = 0;
            }
        }
        emit FlipResult(message, players[_queryId].playerAddress, _queryId);
        isWaiting[_queryId] = false;
    }

    // function possibly not needed?
    function update()
        payable
        public
    {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 30000000;
        //bytes32 queryId = testRandom();

        //commented line below not needed?
        //bytes32 queryId =
        provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit LogNewProvableQuery("Provable query was sent, standing by for callback...");
    }

    function topUpContract()
        public
        payable
        returns(string memory)
    {
        string memory message = "Thank you for your generosity!";
        balance += msg.value;
        return message;
    }

    function getPlayerBalance()
        public
        view
        returns(uint)
    {
        return (playersId[msg.sender].playerBalance);
    }

    function playerWithdrawFunds()
        public
        payable
        returns(string memory)
    {
        string memory message = "Withdrawal Successful!";
        uint playerWithdrawAmount = playersId[msg.sender].playerBalance;
        require(playerWithdrawAmount <= playersId[msg.sender].playerBalance, "You can't withdraw that much!");
        //require(isWaiting[queryId] == false);
        playersId[msg.sender].playerBalance = 0;
        msg.sender.transfer(playerWithdrawAmount);
        return message;
    }

    function getContractBalance()
        public
        view
        onlyOwner
        returns(uint)
    {
        return balance;
    }

    function withdrawFunds(uint256 balanceToTransfer)
        public
        onlyOwner
    {
        require(balanceToTransfer < balance, "You can't withdraw that much!");
        balance -= balanceToTransfer;
        msg.sender.transfer(balanceToTransfer);
        emit WithdrawComplete(owner, balanceToTransfer);
    }

}
