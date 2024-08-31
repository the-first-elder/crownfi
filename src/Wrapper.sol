// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

contract Wrapper is ERC1155 {
    uint256 internal counter = 0; // Number of ERC20 or ERC721 tokens deposited
    mapping(address user => mapping(address erc20Token => uint256 tokenId1155)) public ERC20UserToTokenId;
    mapping(uint256 tokenId1155 => address erc20Token) public ERC1155ToERC20Address;
    mapping(address user => mapping(uint256 tokenId => uint256 amountDeposited)) public ERC20UserToAmount;
    mapping(address erc20tokens => uint256 totalDeposited) public totalERC20Deposited;

    mapping(uint256 tokenId => address erc721Token) public ERC1155ToERC21TokenAddress;
    mapping(address user => mapping(uint256 tokenId1155 => uint256 tokenid721)) public ERC721UserTo721Deposited;

    mapping(uint256 tokenId1155 => uint256 tokenid721) public ERC1155_IdToERC721_Id;
    mapping(uint256 => string) private _tokenURIs;

    // Events
    event DepositERC20(address indexed user, address indexed erc20Token, uint256 amount, uint256 indexed tokenId1155);
    event DepositERC721(
        address indexed user, address indexed erc721Token, uint256 tokenId721, uint256 indexed tokenId1155
    );
    event WithdrawERC20(address indexed user, address indexed erc20Token, uint256 amount, uint256 indexed tokenId1155);
    event WithdrawERC721(
        address indexed user, address indexed erc721Token, uint256 tokenId721, uint256 indexed tokenId1155
    );
    event Mint(address indexed to, uint256 indexed tokenId, uint256 amount, string tokenURI);

    constructor() ERC1155("uri") {}

    // ERC721 interfaceId
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;

    function depositERC20(address erc20Token, uint256 amount, bytes memory data) public {
        require(_supportsERC20(erc20Token), "!ERC20Token");
        uint256 totalDeposited = totalERC20Deposited[erc20Token];
        IERC20 token = IERC20(erc20Token);
        string memory _uri = getBaseUriERC20(erc20Token);

        uint256 ERC1155TokenId = ERC20UserToTokenId[msg.sender][erc20Token];
        if (ERC1155TokenId == 0) {
            counter += 1;
            ERC20UserToTokenId[msg.sender][erc20Token] = counter;
            ERC1155ToERC20Address[counter] = erc20Token;
            ERC1155TokenId = counter;
        }
        uint256 toMint = amount;

        if (totalDeposited < token.balanceOf(address(this))) {
            uint256 diff = token.balanceOf(address(this)) - totalDeposited;
            ERC20UserToAmount[msg.sender][ERC1155TokenId] += amount + diff;
            toMint = amount + diff;
        } else {
            ERC20UserToAmount[msg.sender][ERC1155TokenId] += amount;
        }
        token.transferFrom(msg.sender, address(this), amount);
        totalERC20Deposited[erc20Token] += toMint;
        mint(msg.sender, ERC1155TokenId, toMint, data, _uri);

        emit DepositERC20(msg.sender, erc20Token, amount, ERC1155TokenId); // Emit event
    }

    function depositERC721(address erc721Token, uint256 tokenId, bytes memory data, string memory _uri) public {
        require(_supportsERC721(erc721Token), "!ERC721Token");

        IERC721 nft = IERC721(erc721Token);
        nft.transferFrom(msg.sender, address(this), tokenId);

        counter += 1;
        ERC1155ToERC21TokenAddress[counter] = erc721Token;

        ERC721UserTo721Deposited[msg.sender][counter] = tokenId;
        ERC1155_IdToERC721_Id[counter] = tokenId;
        mint(msg.sender, counter, 1, data, _uri);

        emit DepositERC721(msg.sender, erc721Token, tokenId, counter); // Emit event
    }

    function withdrawERC20(address erc20Token, uint256 amount) public {
        require(_supportsERC20(erc20Token), "!ERC20Token");
        uint256 tokenId = getTokenID(msg.sender, erc20Token);
        _burn(msg.sender, tokenId, amount);
        ERC20UserToAmount[msg.sender][tokenId] -= amount;
        IERC20(erc20Token).transfer(msg.sender, amount);

        emit WithdrawERC20(msg.sender, erc20Token, amount, tokenId); // Emit event
    }

    function withdrawERC721(address erc721Token, uint256 tokenId1155) public {
        require(_supportsERC721(erc721Token), "!ERC721Token");
        uint256 tokenId721 = ERC721UserTo721Deposited[msg.sender][tokenId1155];
        require(balanceOf(msg.sender, tokenId1155) > 0, "not owner");
        address tokenContract = ERC1155ToERC21TokenAddress[tokenId1155];
        IERC721(tokenContract).transferFrom(address(this), msg.sender, tokenId721);
        delete ERC721UserTo721Deposited[msg.sender][tokenId1155];

        emit WithdrawERC721(msg.sender, erc721Token, tokenId721, tokenId1155); // Emit event
    }

    function getTokenID(address user, address _token) public view returns (uint256 tokenID) {
        tokenID = ERC20UserToTokenId[user][_token];
        require(tokenID != 0, "UNREGISTERED_TOKEN");
        return tokenID;
    }

    function getBaseUriERC20(address erc20Address) public view returns (string memory baseURI) {
        string memory name = ERC20(erc20Address).name();
        string memory symbol = ERC20(erc20Address).symbol();

        baseURI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(abi.encodePacked('{"name":"', name, '", "symbol":"', symbol, '"}'))
            )
        );
    }

    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data, string memory tokenURI) private {
        _mint(to, tokenId, amount, data);
        setTokenURI(tokenId, tokenURI);

        // If the receiver is a contract, handle ERC1363 logic
        if (isContract(to)) {
            try IERC1363Receiver(to).onTransferReceived(msg.sender, msg.sender, amount, data) returns (bytes4 response)
            {
                require(response == IERC1363Receiver.onTransferReceived.selector, "ERC1363: transfer rejected");
            } catch {
                // Do nothing...
            }
        }

        emit Mint(to, tokenId, amount, tokenURI); // Emit event
    }

    // Function to set the URI for a specific token ID
    function setTokenURI(uint256 tokenId, string memory tokenURI) public {
        _tokenURIs[tokenId] = tokenURI;
    }

    // Override the uri function to return the token-specific URI
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function _supportsERC20(address contractAddress) internal view returns (bool) {
        try IERC20(contractAddress).totalSupply() returns (uint256) {
            try IERC20(contractAddress).balanceOf(msg.sender) returns (uint256) {
                return true;
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }

    function _supportsERC721(address contractAddress) internal view returns (bool) {
        try IERC165(contractAddress).supportsInterface(_ERC721_INTERFACE_ID) {
            return IERC165(contractAddress).supportsInterface(_ERC721_INTERFACE_ID);
        } catch {
            return false;
        }
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    receive() external payable {
        require(msg.value > 0, "Must send ETH");
    }
}
