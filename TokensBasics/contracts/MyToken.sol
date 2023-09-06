// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    address ownerAddr;

    constructor(uint256 initialSupply) ERC20("Aboba", "AB") {
        _mint(address(this), initialSupply);
    }

    function getAddr() public view returns (address) {
        return address(this);
    }

    function moveFunds(uint amount, address receiver) public {
        _transfer(address(this), receiver, amount);
    }

    function makeAllow(uint addedValue) public returns (uint256) {
        increaseAllowance(address(this), addedValue);
        return allowance(address(this), address(this));
    }

    function callTransfer(address receiver, uint256 amount) public {
        transferFrom(address(this), receiver, amount);
    }
}
