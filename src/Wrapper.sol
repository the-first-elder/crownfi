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
import "@openzeppelin/contracts/interfaces/IERC1363.sol";

contract Wrapper is ERC1155, IERC1363Receiver {
    mapping(address user => mapping(address erc20Token => uint256 tokenId1155)) public ERC20UserToTokenId;
    mapping(uint256 tokenId1155 => address erc20Token) public ERC1155ToERC20Address;
    mapping(address user => mapping(uint256 tokenId => uint256 amountDeposited)) public ERC20UserToAmount;
    mapping(address erc20tokens => uint256 totalDeposited) public totalERC20Deposited;
    mapping(uint256 tokenId => address erc721Token) public ERC1155ToERC21TokenAddress;
    mapping(address user => mapping(uint256 tokenId1155 => uint256 tokenid721)) public ERC721UserTo721Deposited;
    mapping(uint256 tokenId1155 => uint256 tokenid721) public ERC1155_IdToERC721_Id;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address user => bool tranfered) public userHasTransferred;

    uint256 internal counter = 0; // Number of ERC20 or ERC721 tokens deposited
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
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

    function depositERC20(address user, address erc20Token, uint256 amount, bytes memory data)
        public
        returns (uint256 ERC1155TokenId)
    {
        require(_supportsERC20(erc20Token), "!ERC20Token");
        uint256 totalDeposited = totalERC20Deposited[erc20Token];
        IERC20 token = IERC20(erc20Token);
        string memory _uri = getBaseUriERC20(erc20Token);

        ERC1155TokenId = ERC20UserToTokenId[user][erc20Token];
        if (ERC1155TokenId == 0) {
            counter += 1;
            ERC20UserToTokenId[user][erc20Token] = counter;
            ERC1155ToERC20Address[counter] = erc20Token;
            ERC1155TokenId = counter;
        }
        // to prevent double deposit 1363...
        if (!userHasTransferred[user]) token.transferFrom(user, address(this), amount);

        uint256 diff = token.balanceOf(address(this)) - totalDeposited;
        ERC20UserToAmount[user][ERC1155TokenId] += diff;
        totalERC20Deposited[erc20Token] += diff;
        mint(user, ERC1155TokenId, diff, data, _uri);

        emit DepositERC20(msg.sender, erc20Token, amount, ERC1155TokenId);
    }

    function depositERC721(address erc721Token, uint256 tokenId, bytes memory data, string memory _uri)
        public
        returns (uint256 ERC1155TokenId)
    {
        require(_supportsERC721(erc721Token), "!ERC721Token");

        IERC721 nft = IERC721(erc721Token);
        nft.transferFrom(msg.sender, address(this), tokenId);

        counter += 1;
        ERC1155TokenId = counter;
        ERC1155ToERC21TokenAddress[counter] = erc721Token;

        ERC721UserTo721Deposited[msg.sender][counter] = tokenId;
        ERC1155_IdToERC721_Id[counter] = tokenId;
        mint(msg.sender, counter, 1, data, _uri);

        emit DepositERC721(msg.sender, erc721Token, tokenId, counter);
    }

    function withdrawERC20(address erc20Token, uint256 amount) public {
        require(_supportsERC20(erc20Token), "!ERC20Token");
        uint256 tokenId = getERC20TokenID(msg.sender, erc20Token);
        _burn(msg.sender, tokenId, amount);
        ERC20UserToAmount[msg.sender][tokenId] -= amount;
        IERC20(erc20Token).transfer(msg.sender, amount);

        emit WithdrawERC20(msg.sender, erc20Token, amount, tokenId);
    }

    function withdrawERC721(address erc721Token, uint256 tokenId1155) public {
        require(_supportsERC721(erc721Token), "!ERC721Token");
        uint256 tokenId721 = ERC721UserTo721Deposited[msg.sender][tokenId1155];
        require(balanceOf(msg.sender, tokenId1155) > 0, "not owner");
        address tokenContract = ERC1155ToERC21TokenAddress[tokenId1155];
        IERC721(tokenContract).transferFrom(address(this), msg.sender, tokenId721);
        delete ERC721UserTo721Deposited[msg.sender][tokenId1155];

        emit WithdrawERC721(msg.sender, erc721Token, tokenId721, tokenId1155);
    }

    function getERC20TokenID(address user, address _token) public view returns (uint256 tokenID) {
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

        emit Mint(to, tokenId, amount, tokenURI);
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

    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        returns (bytes4)
    {
        require(isERC1363(msg.sender), "caller not 1363..");
        userHasTransferred[from] = true;
        depositERC20(operator, msg.sender, value, data);
        userHasTransferred[from] = false;
        return this.onTransferReceived.selector;
    }

    // Function to check if the token contract supports ERC1363
    function isERC1363(address token) public view returns (bool) {
        try IERC165(token).supportsInterface(type(IERC1363).interfaceId) {
            return IERC165(token).supportsInterface(type(IERC1363).interfaceId);
        } catch {
            return false;
        }
    }

    receive() external payable {
        require(msg.value > 0, "Must send ETH");
    }
}
