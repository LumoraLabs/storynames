// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ERC721URIStorageUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IComposableERC721 } from "src/contract/interface/IComposableERC721.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ComposableERC721 is IComposableERC721, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    struct TokenOwner {
        address ownerAddress;
        uint256 parentTokenId; // 0 if no parent
    }

    mapping(uint256 => TokenOwner) private _tokenIdToOwner;
    mapping(address => mapping(uint256 => uint256[])) private _parentToChildTokens;
    mapping(uint256 => uint256) private _childTokenIndex;
    string private _contractURI;
    uint256 private _nextTokenId; // New variable to track the next token ID

    // Modifier to verify ownership or approval
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

    modifier onlyOwnerOrApprovedOfParent(address parentContract, uint256 parentTokenId) {
        require(_isApprovedOrOwnerOfParent(msg.sender, parentContract, parentTokenId), "Not owner or approved for parent");
        _;
    }

    /// @notice Initializes the contract with a name, symbol, and contract URI.
    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI_,
        address owner
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(owner);
        _contractURI = contractURI_;
        _nextTokenId = 1; // Initialize _nextTokenId
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function rootOwnerOf(uint256 tokenId) public view override returns (address rootOwner) {
        address owner = _tokenIdToOwner[tokenId].ownerAddress;
        return owner != address(0) ? owner : address(0);
    }

    function tokenOwnerOf(uint256 tokenId) external view override returns (address tokenOwner, uint256 parentTokenId, bool isParent) {
        tokenOwner = _tokenIdToOwner[tokenId].ownerAddress;
        parentTokenId = _tokenIdToOwner[tokenId].parentTokenId;
        isParent = parentTokenId > 0;
    }

    function transferToParent(
        address toContract,
        uint256 toTokenId,
        uint256 tokenId
    ) external override onlyOwnerOrApproved(tokenId) {
        require(toContract != address(0) && _isContract(toContract), "Invalid contract address");

        _transfer(msg.sender, toContract, tokenId);

        _tokenIdToOwner[tokenId] = TokenOwner({
            ownerAddress: toContract,
            parentTokenId: toTokenId
        });

        _parentToChildTokens[toContract][toTokenId].push(tokenId);
        _childTokenIndex[tokenId] = _parentToChildTokens[toContract][toTokenId].length - 1;

        emit TransferToParent(toContract, toTokenId, tokenId);
    }

    function transferFromParent(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 tokenId
    ) external override onlyOwnerOrApprovedOfParent(fromContract, fromTokenId) {
        require(to != address(0), "Transfer to zero address");
        require(_tokenIdToOwner[tokenId].ownerAddress == fromContract, "Token is not owned by parent contract");
        require(_tokenIdToOwner[tokenId].parentTokenId == fromTokenId, "Token is not a child of this parent");

        _removeChild(fromContract, fromTokenId, tokenId);

        _tokenIdToOwner[tokenId] = TokenOwner({
            ownerAddress: to,
            parentTokenId: 0
        });

        _transfer(fromContract, to, tokenId);

        emit TransferFromParent(fromContract, fromTokenId, tokenId);
    }

    function mintToParent(
        address toContract,
        uint256 toTokenId,
        string calldata nftMetadataURI
    ) external onlyOwnerOrApprovedOfParent(toContract, toTokenId) returns (uint256 tokenId) {
        require(toContract != address(0) && _isContract(toContract), "Invalid contract address");

        tokenId = _nextTokenId++;
        _mint(toContract, tokenId);
        _setTokenURI(tokenId, nftMetadataURI);

        _tokenIdToOwner[tokenId] = TokenOwner({
            ownerAddress: toContract,
            parentTokenId: toTokenId
        });

        _parentToChildTokens[toContract][toTokenId].push(tokenId);
        _childTokenIndex[tokenId] = _parentToChildTokens[toContract][toTokenId].length - 1;

        emit TransferToParent(toContract, toTokenId, tokenId);
    }

    function _removeChild(address fromContract, uint256 fromTokenId, uint256 tokenId) private {
        uint256 lastTokenIndex = _parentToChildTokens[fromContract][fromTokenId].length - 1;
        uint256 childIndex = _childTokenIndex[tokenId];

        if (childIndex != lastTokenIndex) {
            uint256 lastTokenId = _parentToChildTokens[fromContract][fromTokenId][lastTokenIndex];
            _parentToChildTokens[fromContract][fromTokenId][childIndex] = lastTokenId;
            _childTokenIndex[lastTokenId] = childIndex;
        }

        _parentToChildTokens[fromContract][fromTokenId].pop();
        delete _childTokenIndex[tokenId];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _isApprovedOrOwnerOfParent(
        address spender,
        address parentContract,
        uint256 parentTokenId
    ) internal view returns (bool) {
        IERC721 parentNFT = IERC721(parentContract);

        if (parentNFT.ownerOf(parentTokenId) == spender) {
            return true;
        }

        if (parentNFT.getApproved(parentTokenId) == spender) {
            return true;
        }

        if (parentNFT.isApprovedForAll(parentNFT.ownerOf(parentTokenId), spender)) {
            return true;
        }

        return false;
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function childTokensOfParent(address parentContract, uint256 parentTokenId) external view returns (uint256[] memory) {
        return _parentToChildTokens[parentContract][parentTokenId];
    }
}
