// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Wrapper} from "../src/Wrapper.sol";
import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "../src/MockTokens/MockERC20.sol";
import {MockERC721} from "../src/MockTokens/MockERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract WrapperTest is Test, IERC1155Receiver, ERC165, IERC1363Receiver {
    Wrapper wrapper;
    MockERC20 erc20;
    MockERC721 erc721;
    MockERC20 erc20_v2;
    MockERC721 erc721_v2;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        vm.startPrank(deployer);
        // _registerInterface(type(IERC1155Receiver).interfaceId);
        wrapper = new Wrapper();
        erc20 = new MockERC20();
        erc20_v2 = new MockERC20();
        erc721 = new MockERC721();
        erc721_v2 = new MockERC721();
        vm.deal(address(this), 100 ether);
        vm.stopPrank();
    }

    function test_deployer() public view {
        console2.log(address(wrapper));
    }

    function test_deposit_erc20_should_fail_if_not_erc20token(uint256 amount) public {
        vm.expectRevert(bytes("!ERC20Token"));
        wrapper.depositERC20(address(this), amount, "");
    }

    function test_deposit_erc20_by_user() public {
        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");
        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), 0.5 ether);
        assertEq(erc20.balanceOf(user1), 0.5 ether);
        // // user 1 deposits again..... to same token id
        wrapper.depositERC20(address(erc20), 0.3 ether, "");
        assertEq(wrapper.balanceOf(user1, 1), 0.8 ether);
        assertEq(wrapper.getTokenID(user1, address(erc20)), 1);
        assertEq(erc20.balanceOf(user1), 0.2 ether);

        // user 1 deposits another erc20 token...
        erc20_v2.mint(user1, 1 ether);
        erc20_v2.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20_v2), 0.5 ether, "");
        assertEq(wrapper.balanceOf(user1, 2), 0.5 ether);
        assertEq(erc20_v2.balanceOf(user1), 0.5 ether);
        assertEq(wrapper.getTokenID(user1, address(erc20_v2)), 2);
        vm.stopPrank();

        vm.startPrank(user2);
        erc20_v2.mint(user2, 1 ether);
        erc20_v2.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20_v2), 0.5 ether, "");
        assertEq(wrapper.balanceOf(user2, 3), 0.5 ether);
        assertEq(erc20_v2.balanceOf(user2), 0.5 ether);
        assertEq(wrapper.getTokenID(user2, address(erc20_v2)), 3);
        vm.stopPrank();
        console2.log(wrapper.balanceOf(user2, 3), erc20.balanceOf(user2), wrapper.uri(3));
    }

    function test_no_loss_of_funds_when_another_user_sends_token_to_contact() public {
        erc20.mint(address(wrapper), 1 ether);
        assertEq(erc20.balanceOf(address(wrapper)), 1 ether);
        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");

        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), 1.5 ether); // extra tokens gets added to user1
        assertEq(erc20.balanceOf(user1), 0.5 ether);
    }

    function test_can_deposit_to_contracts_supporting_1363() public {
        erc20.mint(address(this), 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");
        console2.log(wrapper.balanceOf(address(this), 1), erc20.balanceOf(address(this)), wrapper.uri(1));
        assertEq(wrapper.balanceOf(address(this), 1), 0.5 ether);
        assertEq(erc20.balanceOf(address(this)), 0.5 ether);
        // assertEq(wrapper.isContract(address(this)), true);
    }

    function test_deposit_erc721_should_fail_if_not_erc721token(uint256 amount) public {
        vm.expectRevert(bytes("!ERC721Token"));
        wrapper.depositERC721(address(erc20), amount, "", "hello world");
    }

    function test_deposit_erc721_by_user() public {
        vm.startPrank(user1);
        erc721.safeMint(user1);
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", "the first nft");
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), "the first nft");
        assertEq(erc721.ownerOf(0), address(wrapper));

        // user1 deposits another nft...
        erc721.safeMint(user1);
        erc721.approve(address(wrapper), 1);
        wrapper.depositERC721(address(erc721), 1, "", "the second nft");
        assertEq(wrapper.balanceOf(user1, 2), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 2);
        assertEq(wrapper.uri(2), "the second nft");
        assertEq(erc721.ownerOf(1), address(wrapper));

        vm.stopPrank();
        // user 2 deposits another nft

        vm.startPrank(user2);
        erc721_v2.safeMint(user2);
        erc721_v2.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721_v2), 0, "", "the third nft");
        assertEq(wrapper.balanceOf(user2, 3), 1);
        assertEq(erc721_v2.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(3), "the third nft");
        assertEq(erc721_v2.ownerOf(0), address(wrapper));
    }

    function test_withdrawal_of_erc20() public {
        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");
        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), 0.5 ether);
        assertEq(erc20.balanceOf(user1), 0.5 ether);
        vm.stopPrank();
        // user2 deposits...
        vm.startPrank(user2);
        erc20.mint(user2, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");
        console2.log(wrapper.balanceOf(user2, 1), erc20.balanceOf(user2), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user2, 2), 0.5 ether);
        assertEq(erc20.balanceOf(user2), 0.5 ether);
        vm.stopPrank();
        // withdraw
        vm.startPrank(user1);
        wrapper.withdrawERC20(address(erc20), 0.5 ether);
        assertEq(wrapper.balanceOf(user1, 1), 0);
        assertEq(erc20.balanceOf(user1), 1 ether);
    }

    function test_cannot_withdraw_erc20_if_user_doesnt_deposit() public {
        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 0.5 ether, "");
        console2.log(wrapper.balanceOf(user1, 1), erc20.balanceOf(user1), wrapper.uri(1));
        assertEq(wrapper.balanceOf(user1, 1), 0.5 ether);
        assertEq(erc20.balanceOf(user1), 0.5 ether);
        vm.stopPrank();

        // user2 withdraws.
        vm.startPrank(user2);
        vm.expectRevert();
        wrapper.withdrawERC20(address(erc20), 0.5 ether);
    }

    function test_cannot_withdraw_erc20_than_deposited() public {
        vm.startPrank(user1);
        erc20.mint(user1, 1 ether);
        erc20.approve(address(wrapper), 1 ether);
        wrapper.depositERC20(address(erc20), 1 ether, "");
        assertEq(wrapper.balanceOf(user1, 1), 1 ether);
        assertEq(erc20.balanceOf(user1), 0);

        // user1 withdraws.
        vm.expectRevert();
        wrapper.withdrawERC20(address(erc20), 2 ether);
    }

    function test_withdrawal_of_erc721() public {
        vm.startPrank(user1);
        erc721.safeMint(user1);
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", "the first nft");
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), "the first nft");
        assertEq(erc721.ownerOf(0), address(wrapper));

        // withdrawal
        wrapper.withdrawERC721(address(erc721), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 0);
        assertEq(erc721.balanceOf(user1), 1);
        assertEq(erc721.ownerOf(0), user1);
    }

    function test_cannot_withdraw_erc721_if_user_doesnt_deposit() public {
        vm.startPrank(user1);
        erc721.safeMint(user1);
        erc721.approve(address(wrapper), 0);
        wrapper.depositERC721(address(erc721), 0, "", "the first nft");
        assertEq(wrapper.balanceOf(user1, 1), 1);
        assertEq(erc721.balanceOf(address(wrapper)), 1);
        assertEq(wrapper.uri(1), "the first nft");
        assertEq(erc721.ownerOf(0), address(wrapper));

        // withdrawal
        vm.startPrank(user2);
        vm.expectRevert();
        wrapper.withdrawERC721(address(erc721), 1);
    }

    function test_contract_can_receive_ether() public {
        (bool success,) = address(wrapper).call{value: 1 ether}("");
        require(success, "Failed to send Ether");
        assertEq(address(wrapper).balance, 1 ether);
    }

    // Handle the receipt of a single ERC1155 token type
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Your custom logic here

        return this.onERC1155Received.selector;
    }

    // Handle the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        // Your custom logic here

        return this.onERC1155BatchReceived.selector;
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data)
        public
        override
        returns (bytes4)
    {
        // Implement your custom logic here
        console2.log("here....");
        // Return the selector of this function to confirm the token transfer was successful
        return this.onTransferReceived.selector;
    }

    // Override supportsInterface to check for the interface ID of IERC1155Receiver
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
