pragma solidity ^0.8.0;

// SPDX-License-Identifier: No License

contract Oracle {
    address public admin;
    uint public rand;
    
    constructor() {
        admin = msg.sender;
    }
    
    function feedRandomness(uint _rand) external {
        require(msg.sender == admin, "only admin is allowed");
        rand = _rand;
    }
}