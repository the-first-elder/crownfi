// // SPDX-License-Identifier: MIT
// // Compatible with OpenZeppelin Contracts ^5.0.0
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/interfaces/IERC1363.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// contract MOCK1363 is ERC20, IERC1363{
//     constructor() ERC20("MyToken", "MTK") {}

//     function mint(address to, uint256 amount) public {
//         _mint(to, amount);
//     }
//     /**
//      * @dev Transfers tokens to a specified address and calls a function on the recipient.
//      * @param to The address to transfer tokens to.
//      * @param value The amount of tokens to transfer.
//      * @param data The data to be passed to the recipient's function.
//      * @return true if the transfer was successful, false otherwise.
//      */
//     function transferAndCall(address to, uint256 value, bytes calldata data) external override returns (bool) {
//         require(to != address(0), "ERC20: transfer to the zero address");
//         require(value > 0, "ERC20: transfer of 0 values");

//         bool success;
//         (success, ) = to.call{gas: gasleft() - 21000}(data);
//         require(success, "ERC20: transfer and call failed");

//         _transfer(_msgSender(), to, value);
//         emit Transfer(_msgSender(), to, value);

//         return true;
//     }

//     /**
//      * @dev Transfers tokens to a specified address on behalf of another address and calls a function on the recipient.
//      * @param from The address from which the tokens are transferred.
//      * @param to The address to transfer tokens to.
//      * @param value The amount of tokens to transfer.
//      * @param data The data to be passed to the recipient's function.
//      * @return true if the transfer was successful, false otherwise.
//      */
//     function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external override returns (bool) {
//         require(to != address(0), "ERC20: transfer to the zero address");
//         require(value > 0, "ERC20: transfer of 0 values");

//         _approve(from, _msgSender(), value);
//         _transfer(from, to, value);
//         emit Transfer(from, to, value);

//         bool success;
//         (success, ) = to.call{gas: gasleft() - 21000}(data);
//         require(success, "ERC20: transferFrom and call failed");

//         return true;
//     }
// }
