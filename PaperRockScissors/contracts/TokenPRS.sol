// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenPRS is ERC20 {
    address[] receivers = [
        0xAe639c701629824D576231119C0FB5B855cF1dF8,
        0xbf8c1fEF94Cb4f1303D2f0e4C994B8bd979270C6,
        0x8BDbd2760c5386e09210FDca270380bA2A2db41d,
        0x53ec7446F3C7F205e7b3B17EF07182DbC51E761d
    ];

    constructor(uint initialSupply) ERC20("PaperRockScissors", "PRS") {
        _mint(address(this), initialSupply);
        for (uint i = 0; i < receivers.length; i++) {
            _transfer(address(this), receivers[i], 50);
        }
    }
}
