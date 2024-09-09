// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Wrapper} from "../src/Wrapper.sol";
import {Script, console2} from "forge-std/Script.sol";
import {MockERC20} from "../src/MockTokens/MockERC20.sol";
import {MockERC721} from "../src/MockTokens/MockERC721.sol";
import {MOCK1363} from "../src/MockTokens/MOCK1363.sol";

contract DeployWrapper is Script {
    Wrapper wrapper;
    MockERC20 erc20;
    MockERC721 erc721;
    MOCK1363 mock1363;

    function run() public {
        vm.startBroadcast();
        wrapper = new Wrapper();
        erc20 = new MockERC20();
        erc721 = new MockERC721();
        mock1363 = new MOCK1363();
        vm.stopBroadcast();
        console2.log("wrapper address:", address(wrapper));
        console2.log("erc20 address:", address(erc20));
        console2.log("erc721 address:", address(erc721));
        console2.log("mock1353 address:", address(mock1363));
    }
}
