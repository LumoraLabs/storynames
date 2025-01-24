// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract EAStoryNameSBT is ERC721, Ownable {
   uint256 private _tokenIds;
    string private baseTokenURI;

    // Mapping from token ID to locked status (always true for SBT)
    mapping(uint256 => bool) private _locked;

    event Locked(uint256 indexed tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner
    ) ERC721(name_, symbol_) {
        baseTokenURI = baseURI_;
        _initializeOwner(owner);

    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function safeMint(address to) public onlyOwner {
        require(balanceOf(to) == 0, "Only one SBT per address is allowed");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _safeMint(to, newTokenId);

        _locked[newTokenId] = true; // Mark the token as locked (non-transferable)
        emit Locked(newTokenId);
    }

    // Override to prevent transfers
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override {
        revert("SoulboundToken: Transfers are not allowed");
    }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     uint256 batchSize
    // ) internal override {
    //     require(from == address(0) || to == address(0), "Soulbound tokens cannot be transferred");
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // Optional: Burn function to allow users to "revoke" their SBT
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not authorized to burn");
        _burn(tokenId);
    }

    // Function to check if a token is locked (always true for SBT)
    function locked(uint256 tokenId) public view returns (bool) {
        require(ownerOf(tokenId) != address(0));
        return _locked[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        return baseTokenURI;
    }

}
