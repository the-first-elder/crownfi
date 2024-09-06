// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Wrapper} from "../src/Wrapper.sol";
import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockTokens/MockERC20.sol";
import {MockERC721} from "../src/MockTokens/MockERC721.sol";
// import {MOCK1363} from "../src/MockTokens/MOCK1363.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract WrapperTest is Test {
    Wrapper wrapper;
    MockERC20 erc20;
    MockERC721 erc721;
    MockERC20 erc20_v2;
    MockERC721 erc721_v2;
    // MOCK1363 mock1363;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        vm.startPrank(deployer);
        wrapper = new Wrapper();
        erc20 = new MockERC20();
        erc20_v2 = new MockERC20();
        erc721 = new MockERC721();
        erc721_v2 = new MockERC721();
        // mock1363= new MOCK1363();
        vm.deal(address(this), 100 ether);
        vm.stopPrank();
    }

    function test_deployer() public view {
        console2.log(address(wrapper));
    }

    function test_deposit_erc20_should_fail_if_not_erc20token(uint256 amount) public {
        vm.expectRevert(bytes("!ERC20Token"));
        wrapper.depositERC20(user1, address(this), amount, "");
    }

    function test_deposit_erc20_by_user() public {
        uint256 firstDepositAmount = 0.5 ether;
        uint256 secondDepositAmount = 0.3 ether;
        uint256 erc20_v2DepositAmount = 0.5 ether;

        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(user1, address(erc20), firstDepositAmount, "");

        assertEq(wrapper.balanceOf(user1, 1), firstDepositAmount);
        assertEq(erc20.balanceOf(user1), 0.5 ether);

        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        wrapper.depositERC20(user1, address(erc20), secondDepositAmount, "");
        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));

        assertEq(wrapper.balanceOf(user1, 1), 0.8 ether);
        assertEq(wrapper.getERC20TokenID(user1, address(erc20)), 1);
        assertEq(erc20.balanceOf(user1), 0.2 ether);

        // // test wtih another erc20 token....
        erc20_v2.mint(user1, 1 ether);
        erc20_v2.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(user1, address(erc20_v2), erc20_v2DepositAmount, "");
        assertEq(wrapper.balanceOf(user1, 2), erc20_v2DepositAmount);
        assertEq(erc20_v2.balanceOf(user1), 0.5 ether);
        assertEq(wrapper.getERC20TokenID(user1, address(erc20_v2)), 2);
        vm.stopPrank();

        vm.startPrank(user2);
        erc20_v2.mint(user2, 1 ether);
        erc20_v2.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(user2, address(erc20_v2), erc20_v2DepositAmount, "");
        assertEq(wrapper.balanceOf(user2, 3), erc20_v2DepositAmount);
        assertEq(erc20_v2.balanceOf(user2), 0.5 ether);
        assertEq(wrapper.getERC20TokenID(user2, address(erc20_v2)), 3);
        vm.stopPrank();

        console2.log(wrapper.balanceOf(user2, 3), erc20.balanceOf(user2), wrapper.uri(3));
    }

    function test_no_loss_of_funds_when_another_user_sends_token_to_contract() public {
        uint256 initialMintAmount = 1 ether;
        uint256 userDepositAmount = 0.5 ether;

        erc20.mint(address(wrapper), initialMintAmount);
        assertEq(erc20.balanceOf(address(wrapper)), initialMintAmount);

        vm.startPrank(user1);
        erc20.mint(user1, initialMintAmount);
        erc20.approve(address(wrapper), initialMintAmount);
        wrapper.depositERC20(user1, address(erc20), userDepositAmount, "");

        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), initialMintAmount + userDepositAmount);
        assertEq(erc20.balanceOf(user1), 0.5 ether);
    }

    // function test_can_deposit_to_contracts_supporting_1363() public {
    //     uint256 depositAmount = 0.5 ether;

    //     erc20.mint(address(this), 1 ether);
    //     erc20.approve(address(wrapper), 1 ether);
    //     wrapper.depositERC20(address(this),address(erc20), depositAmount, "");

    //     console2.log(wrapper.balanceOf(address(this), 1), erc20.balanceOf(address(this)), wrapper.uri(1));
    //     assertEq(wrapper.balanceOf(address(this), 1), depositAmount);
    //     assertEq(erc20.balanceOf(address(this)), 0.5 ether);
    // }

    function test_deposit_erc721_should_fail_if_not_erc721token(uint256 amount) public {
        vm.expectRevert(bytes("!ERC721Token"));
        wrapper.depositERC721(address(erc20), amount, "", "hello world");
    }

    function test_deposit_erc721_by_user() public {
        vm.startPrank(user1);
        erc721.safeMint(user1, "nft1");
        erc721.approve(address(wrapper), 0);
        uint256 nftTokenId1 = wrapper.depositERC721(address(erc721), 0, "", erc721.tokenURI(0));

        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), erc721.tokenURI(0));
        assertEq(erc721.ownerOf(0), address(wrapper));
        console2.log("nftTokenId1", nftTokenId1);

        erc721.safeMint(user1, "nft2");
        erc721.approve(address(wrapper), 1);
        uint256 nftTokenId2 = wrapper.depositERC721(address(erc721), 1, "", erc721.tokenURI(1));

        assertEq(wrapper.balanceOf(user1, 2), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 2);
        assertEq(wrapper.uri(2), erc721.tokenURI(1));
        assertEq(erc721.ownerOf(1), address(wrapper));
        console2.log("nftTokenId2", nftTokenId2);
        vm.stopPrank();

        vm.startPrank(user2);
        erc721_v2.safeMint(user2, "nft3");
        erc721_v2.approve(address(wrapper), 0);
        uint256 nftTokenId3 = wrapper.depositERC721(address(erc721_v2), 0, "", erc721.tokenURI(0));

        assertEq(wrapper.balanceOf(user2, 3), 1);
        assertEq(erc721_v2.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(3), erc721.tokenURI(0));
        assertEq(erc721_v2.ownerOf(0), address(wrapper));
        console2.log("nftTokenId3", nftTokenId3);
    }

    function test_withdrawal_of_erc20() public {
        uint256 depositAmount = 0.5 ether;

        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(user1, address(erc20), depositAmount, "");
        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), depositAmount);
        assertEq(erc20.balanceOf(user1), 0.5 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        erc20.mint(user2, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(user2, address(erc20), depositAmount, "");
        console2.log(wrapper.balanceOf(user2, 1), erc20.balanceOf(user2), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user2, 2), depositAmount);
        assertEq(erc20.balanceOf(user2), 0.5 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        wrapper.withdrawERC20(address(erc20), depositAmount);
        assertEq(wrapper.balanceOf(user1, 1), 0);
        assertEq(erc20.balanceOf(user1), 1 ether);
    }

    function test_cannot_withdraw_erc20_if_user_doesnt_deposit() public {
        uint256 depositAmount = 0.5 ether;
        uint256 initialDeposit = 1 ether;
        // Setup: user1 deposits 0.5 ether of ERC20
        vm.startPrank(user1);
        erc20.mint(user1, initialDeposit);
        erc20.approve(address(wrapper), initialDeposit);
        wrapper.depositERC20(user1, address(erc20), depositAmount, "");
        assertEq(wrapper.balanceOf(user1, 1), depositAmount);
        assertEq(erc20.balanceOf(user1), initialDeposit - depositAmount);
        vm.stopPrank();

        // Test: user2 attempts to withdraw without depositing
        vm.startPrank(user2);
        vm.expectRevert();
        wrapper.withdrawERC20(address(erc20), depositAmount);
    }

    function test_cannot_withdraw_erc20_than_deposited() public {
        uint256 excessWithdrawalAmount = 2 ether;
        uint256 initialDeposit = 1 ether;

        // Setup: user1 deposits 1 ether of ERC20
        vm.startPrank(user1);
        erc20.mint(user1, initialDeposit);
        erc20.approve(address(wrapper), initialDeposit);
        wrapper.depositERC20(user1, address(erc20), initialDeposit, "");
        assertEq(wrapper.balanceOf(user1, 1), initialDeposit);
        assertEq(erc20.balanceOf(user1), 0);

        // Test: user1 tries to withdraw more than the deposit (2 ether)
        vm.expectRevert();
        wrapper.withdrawERC20(address(erc20), excessWithdrawalAmount);
    }

    function test_withdrawal_of_erc721() public {
        // Setup: user1 deposits an ERC721 token (ID 0)
        vm.startPrank(user1);
        erc721.safeMint(user1, "nft1");
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", erc721.tokenURI(0));
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), erc721.tokenURI(0));
        assertEq(erc721.ownerOf(0), address(wrapper));

        // Test: user1 withdraws the ERC721 token
        wrapper.withdrawERC721(address(erc721), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 0);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.ownerOf(0), user1);
    }

    function test_cannot_withdraw_erc721_if_user_doesnt_deposit() public {
        // Setup: user1 deposits an ERC721 token (ID 0)
        vm.startPrank(user1);
        erc721.safeMint(user1, "nft1");
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", erc721.tokenURI(0));
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), erc721.tokenURI(0));
        assertEq(erc721.ownerOf(0), address(wrapper));
        vm.stopPrank();

        // Test: user2 tries to withdraw user1's ERC721 token
        vm.startPrank(user2);
        vm.expectRevert();
        wrapper.withdrawERC721(address(erc721), 1);
    }

    function test_cannot_withdraw_erc721_of_another_user() public {
        // Setup: user1 deposits an ERC721 token (ID 0)
        vm.startPrank(user1);
        erc721.safeMint(user1, "nft1");
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", erc721.tokenURI(0));
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), erc721.tokenURI(0));
        assertEq(erc721.ownerOf(0), address(wrapper));
        vm.stopPrank();

        // Setup: user2 deposits another ERC721 token (ID 1)
        vm.startPrank(user2);
        erc721.safeMint(user2, "nft2");
        erc721.approve(address(wrapper), 1);
        wrapper.depositERC721(address(erc721), 1, "", erc721.tokenURI(1));
        assertEq(wrapper.balanceOf(user2, 2), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 2);
        assertEq(wrapper.uri(2), erc721.tokenURI(1));
        assertEq(erc721.ownerOf(1), address(wrapper));
        vm.stopPrank();

        // Test: user2 tries to withdraw user1's ERC721 token
        vm.startPrank(user2);
        vm.expectRevert();
        wrapper.withdrawERC721(address(erc721), 1);
    }

    function test_contract_can_receive_ether() public {
        (bool success,) = address(wrapper).call{value: 1 ether}("");
        require(success, "Failed to send Ether");
        assertEq(address(wrapper).balance, 1 ether);
    }

    function test_cannot_callonTransferReceived_if_external_contract_doesnt_support_1363() public {
        vm.startPrank(address(erc20));
        erc20.mint(address(erc20), 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        assertEq(wrapper.isERC1363(address(erc20)), false);
        vm.expectRevert(bytes("caller not 1363.."));
        wrapper.onTransferReceived(user1, address(erc20), 0.5 ether, "");
    }
}
