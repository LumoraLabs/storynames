// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IComposableERC721 {
    event TransferToParent(address indexed parentContract, uint256 indexed parentTokenId, uint256 childTokenId);
    event TransferFromParent(address indexed parentContract, uint256 indexed parentTokenId, uint256 childTokenId);

    function rootOwnerOf(uint256 tokenId) external view returns (address rootOwner);
    function tokenOwnerOf(uint256 tokenId) external view returns (address tokenOwner, uint256 parentTokenId, bool isParent);
    function transferToParent(address toContract, uint256 toTokenId, uint256 tokenId) external;
    function transferFromParent(address fromContract, uint256 fromTokenId, address to, uint256 tokenId) external;
}