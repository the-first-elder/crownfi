// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Wrapper} from "../src/Wrapper.sol";
import {Script, console2} from "forge-std/Script.sol";
import {MockERC20} from "../src/MockTokens/MockERC20.sol";
import {MockERC721} from "../src/MockTokens/MockERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract DeployWrapper is Script {
    Wrapper wrapper;
    MockERC20 erc20;
    MockERC721 erc721;

    function run() public {
        vm.startBroadcast();
        wrapper = new Wrapper();
        erc20 = new MockERC20();
        erc721 = new MockERC721();
        vm.stopBroadcast();
        console2.log("wrapper address:", address(wrapper));
        console2.log("erc20 address:", address(erc20));
        console2.log("erc721 address:", address(erc721));
    }
}
