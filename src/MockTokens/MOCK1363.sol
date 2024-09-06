// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1363} from "./ERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MOCK1363 is ERC1363 {
    address owner;

    constructor() ERC20("testToken", "tkt") {
        owner = msg.sender;
        _mint(msg.sender, 1 ether);
    }

    function freeMint(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
