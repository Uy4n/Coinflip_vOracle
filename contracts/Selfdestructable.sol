// SPDX-License-Identifier: UNLICENSED;
import"./Ownable.sol";
pragma solidity >= 0.5.16 <0.7.0;

contract Selfdestructable is Ownable{
    function close() public onlyOwner{
        address payable owner;
        selfdestruct(owner);
    }
}
