// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC721URIStorageUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ISPGNFT } from "src/contract/interface/ISPGNFT.sol";
import { IComposableERC721 } from "src/contract/interface/IComposableERC721.sol";
import { Errors as SPGErrors } from "src/contract/lib/Errors.sol";
import { SPGNFTLib } from "src/contract/lib/SPGNFTLib.sol";

contract ComposableSPG is ISPGNFT, ERC721URIStorageUpgradeable, AccessControlUpgradeable, IComposableERC721 {    
    /// @dev Storage structure for the SPGNFTSotrage.
    /// @param _maxSupply The maximum supply of the collection.
    /// @param _totalSupply The total minted supply of the collection.
    /// @param _mintFee The fee to mint an NFT from the collection.
    /// @param _mintFeeToken The token to pay for minting.
    /// @param _mintFeeRecipient The address to receive mint fees.
    /// @param _mintOpen The status of minting, whether it is open or not.
    /// @param _publicMinting True if the collection is open for everyone to mint.
    /// @param _baseURI The base URI for the collection. If baseURI is not empty, tokenURI will be
    /// either baseURI + token ID (if nftMetadataURI is empty) or baseURI + nftMetadataURI.
    /// @custom:storage-location erc7201:story-protocol-periphery.SPGNFT
    struct SPGNFTStorage {
        uint32 _maxSupply;
        uint32 _totalSupply;
        uint256 _mintFee;
        address _mintFeeToken;
        address _mintFeeRecipient;
        bool _mintOpen;
        bool _publicMinting;
        string _baseURI;
        string _contractURI;
    }

        // keccak256(abi.encode(uint256(keccak256("story-protocol-periphery.SPGNFT")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant SPGNFTStorageLocation = 0x66c08f80d8d0ae818983b725b864514cf274647be6eb06de58ff94d1defb6d00;

    /// @dev The address of the DerivativeWorkflows contract.
    address public immutable DERIVATIVE_WORKFLOWS_ADDRESS;

    /// @dev The address of the GroupingWorkflows contract.
    address public immutable GROUPING_WORKFLOWS_ADDRESS;

    /// @dev The address of the LicenseAttachmentWorkflows contract.
    address public immutable LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS;

    /// @dev The address of the RegistrationWorkflows contract.
    address public immutable REGISTRATION_WORKFLOWS_ADDRESS;

    /// @dev The address of the Storynames contract.
    address public immutable STORYNAME_ADDRESS;

    struct TokenOwner {
        address ownerAddress;
        uint256 parentTokenId; // 0 if no parent
    }

    mapping(uint256 => TokenOwner) private _tokenIdToOwner;
    mapping(address => mapping(uint256 => uint256[])) private _parentToChildTokens;
    mapping(uint256 => uint256) private _childTokenIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address derivativeWorkflows,
        address groupingWorkflows,
        address licenseAttachmentWorkflows,
        address registrationWorkflows, 
        address storynameContract
    ) {
        if (
            derivativeWorkflows == address(0) ||
            groupingWorkflows == address(0) ||
            licenseAttachmentWorkflows == address(0) ||
            registrationWorkflows == address(0) ||
            storynameContract == address(0)
        ) revert SPGErrors.SPGNFT__ZeroAddressParam();

        DERIVATIVE_WORKFLOWS_ADDRESS = derivativeWorkflows;
        GROUPING_WORKFLOWS_ADDRESS = groupingWorkflows;
        LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS = licenseAttachmentWorkflows;
        REGISTRATION_WORKFLOWS_ADDRESS = registrationWorkflows;
        STORYNAME_ADDRESS = storynameContract;
        
        _disableInitializers();
    }
    // Modifier to verify ownership or approval
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

    // @notice Modifier to restrict access to workflow contracts.
    modifier onlyPeriphery() {
        if (
            msg.sender != DERIVATIVE_WORKFLOWS_ADDRESS &&
            msg.sender != GROUPING_WORKFLOWS_ADDRESS &&
            msg.sender != LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS &&
            msg.sender != REGISTRATION_WORKFLOWS_ADDRESS
        ) revert SPGErrors.SPGNFT__CallerNotPeripheryContract();
        _;
    }

    modifier onlyOwnerOrApprovedOfParent(address parentContract, uint256 parentTokenId) {
        require(_isApprovedOrOwnerOfParent(msg.sender, parentContract, parentTokenId), "Not owner or approved for parent");
        _;
    }
    
    modifier onlyStorynameOwner(address caller) {
        IERC721 StorynameNFT = IERC721(STORYNAME_ADDRESS);
        require(StorynameNFT.balanceOf(caller) > 0, "Not a Storyname owner");
        _;
    }

    /// @dev Initializes the SPGNFT collection.
    /// @dev If mint fee is non-zero, mint token must be set.
    /// @param initParams The initialization parameters for the collection. See {ISPGNFT-InitParams}
    function initialize(ISPGNFT.InitParams calldata initParams) public initializer {
        if (initParams.mintFee > 0 && initParams.mintFeeToken == address(0)) revert SPGErrors.SPGNFT__ZeroAddressParam();
        if (initParams.maxSupply == 0) revert SPGErrors.SPGNFT__ZeroMaxSupply();

        // grant roles to owner and periphery workflow contracts
        _grantRoles(initParams.owner);

        SPGNFTStorage storage $ = _getSPGNFTStorage();
        $._maxSupply = initParams.maxSupply;
        $._mintFee = initParams.mintFee;
        $._mintFeeToken = initParams.mintFeeToken;
        $._mintFeeRecipient = initParams.mintFeeRecipient;
        $._mintOpen = initParams.mintOpen;
        $._publicMinting = initParams.isPublicMinting;
        $._baseURI = initParams.baseURI;
        $._contractURI = initParams.contractURI;

        __ERC721_init(initParams.name, initParams.symbol);
    }

    /// @notice Returns the total minted supply of the collection.
    function totalSupply() public view returns (uint256) {
        return uint256(_getSPGNFTStorage()._totalSupply);
    }

    /// @notice Returns the current mint fee of the collection.
    function mintFee() public view returns (uint256) {
        return _getSPGNFTStorage()._mintFee;
    }

    /// @notice Returns the current mint token of the collection.
    function mintFeeToken() public view returns (address) {
        return _getSPGNFTStorage()._mintFeeToken;
    }

    /// @notice Returns the current mint fee recipient of the collection.
    function mintFeeRecipient() public view returns (address) {
        return _getSPGNFTStorage()._mintFeeRecipient;
    }

    /// @notice Returns true if the collection is open for minting.
    function mintOpen() public view returns (bool) {
        return _getSPGNFTStorage()._mintOpen;
    }

    /// @notice Returns true if the collection is open for public minting.
    function publicMinting() public view returns (bool) {
        return _getSPGNFTStorage()._publicMinting;
    }

    /// @notice Returns the base URI for the collection.
    /// @dev If baseURI is not empty, tokenURI will be either or baseURI + nftMetadataURI
    /// or baseURI + token ID (if nftMetadataURI is empty).
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /// @notice Returns the contract URI for the collection.
    function contractURI() external view returns (string memory) {
        return _getSPGNFTStorage()._contractURI;
    }

    /// @notice Sets the fee to mint an NFT from the collection. Payment is in the designated currency.
    /// @dev Only callable by the admin role.
    /// @param fee The new mint fee paid in the mint token.
    function setMintFee(uint256 fee) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._mintFee = fee;
    }

    /// @notice Sets the mint token for the collection.
    /// @dev Only callable by the admin role.
    /// @param token The new mint token for mint payment.
    function setMintFeeToken(address token) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._mintFeeToken = token;
    }

    /// @notice Sets the recipient of mint fees.
    /// @dev Only callable by the fee recipient.
    /// @param newFeeRecipient The new fee recipient.
    function setMintFeeRecipient(address newFeeRecipient) external {
        if (msg.sender != _getSPGNFTStorage()._mintFeeRecipient) {
            revert SPGErrors.SPGNFT__CallerNotFeeRecipient();
        }
        _getSPGNFTStorage()._mintFeeRecipient = newFeeRecipient;
    }

    /// @notice Sets the minting status.
    /// @dev Only callable by the admin role.
    /// @param mintOpen Whether minting is open or not.
    function setMintOpen(bool mintOpen) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._mintOpen = mintOpen;
    }

    /// @notice Sets the public minting status.
    /// @dev Only callable by the admin role.
    /// @param isPublicMinting Whether the collection is open for public minting or not.
    function setPublicMinting(bool isPublicMinting) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._publicMinting = isPublicMinting;
    }

    /// @notice Sets the base URI for the collection. If baseURI is not empty, tokenURI will be
    /// either baseURI + token ID (if nftMetadataURI is empty) or baseURI + nftMetadataURI.
    /// @dev Only callable by the admin role.
    /// @param baseURI The new base URI for the collection.
    function setBaseURI(string memory baseURI) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._baseURI = baseURI;
    }

    /// @notice Sets the contract URI for the collection.
    /// @dev Only callable by the admin role.
    /// @param contractURI The new contract URI for the collection. Follows ERC-7572 standard.
    ///        See https://eips.ethereum.org/EIPS/eip-7572
    function setContractURI(string memory contractURI) external onlyRole(SPGNFTLib.ADMIN_ROLE) {
        _getSPGNFTStorage()._contractURI = contractURI;

        emit ContractURIUpdated();
    }
    /// @notice Mints an NFT from the collection. Only callable by the minter role.
    /// @param to The address of the recipient of the minted NFT.
    /// @param nftMetadataURI OPTIONAL. The URI of the desired metadata for the newly minted NFT.
    /// @return tokenId The ID of the minted NFT.
    function mint(address to, string calldata nftMetadataURI) public virtual onlyStorynameOwner(to) returns (uint256 tokenId) {
        if (!_getSPGNFTStorage()._publicMinting && !hasRole(SPGNFTLib.MINTER_ROLE, msg.sender)) {
            revert SPGErrors.SPGNFT__MintingDenied();
        }
        tokenId = _mintToken({ to: to, payer: msg.sender, nftMetadataURI: nftMetadataURI });
    }

    /// @notice Mints an NFT from the collection. Only callable by the Periphery contracts.
    /// @param to The address of the recipient of the minted NFT.
    /// @param payer The address of the payer for the mint fee.
    /// @param nftMetadataURI OPTIONAL. The URI of the desired metadata for the newly minted NFT.
    /// @return tokenId The ID of the minted NFT.
    function mintByPeriphery(
        address to,
        address payer,
        string calldata nftMetadataURI
    ) public virtual onlyPeriphery onlyStorynameOwner(tx.origin) returns (uint256 tokenId) {
        tokenId = _mintToken({ to: to, payer: payer, nftMetadataURI: nftMetadataURI });
    }

    /// @dev Withdraws the contract's token balance to the fee recipient.
    /// @param token The token to withdraw.
    function withdrawToken(address token) public {
        IERC20(token).transfer(_getSPGNFTStorage()._mintFeeRecipient, IERC20(token).balanceOf(address(this)));
    }

    /// @dev Supports ERC165 interface.
    /// @param interfaceId The interface identifier.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, ERC721URIStorageUpgradeable, IERC165) returns (bool) {
        return interfaceId == type(ISPGNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Mints an NFT from the collection.
    /// @param to The address of the recipient of the minted NFT.
    /// @param payer The address of the payer for the mint fee.
    /// @param nftMetadataURI OPTIONAL. The URI of the desired metadata for the newly minted NFT.
    /// @return tokenId The ID of the minted NFT.
    function _mintToken(address to, address payer, string calldata nftMetadataURI) internal returns (uint256 tokenId) {
        SPGNFTStorage storage $ = _getSPGNFTStorage();
        if (!$._mintOpen) revert SPGErrors.SPGNFT__MintingClosed();
        if ($._totalSupply + 1 > $._maxSupply) revert SPGErrors.SPGNFT__MaxSupplyReached();

        if ($._mintFeeToken != address(0) && $._mintFee > 0) {
            IERC20($._mintFeeToken).transferFrom(payer, address(this), $._mintFee);
        }

        tokenId = ++$._totalSupply;
        _mint(to, tokenId);

        if (bytes(nftMetadataURI).length > 0) _setTokenURI(tokenId, nftMetadataURI);
    }

    /// @dev Base URI for computing tokenURI.
    /// @dev If baseURI is not empty, tokenURI will be either or baseURI + nftMetadataURI
    /// or baseURI + token ID (if nftMetadataURI is empty).
    /// @return baseURI The base URI for the collection.
    function _baseURI() internal view override returns (string memory) {
        return _getSPGNFTStorage()._baseURI;
    }

    /// @dev Grants minter and admin roles to the owner and periphery workflow contracts.
    /// @param owner The address of the collection owner.
    function _grantRoles(address owner) internal {
        // grant roles to owner
        _grantRole(SPGNFTLib.ADMIN_ROLE, owner);
        _grantRole(SPGNFTLib.MINTER_ROLE, owner);

        // grant roles to periphery workflow contracts
        _grantRole(SPGNFTLib.ADMIN_ROLE, DERIVATIVE_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.MINTER_ROLE, DERIVATIVE_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.ADMIN_ROLE, GROUPING_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.MINTER_ROLE, GROUPING_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.ADMIN_ROLE, LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.MINTER_ROLE, LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.ADMIN_ROLE, REGISTRATION_WORKFLOWS_ADDRESS);
        _grantRole(SPGNFTLib.MINTER_ROLE, REGISTRATION_WORKFLOWS_ADDRESS);
    }

    //
    // Upgrade
    //

    /// @dev Returns the storage struct of SPGNFT.
    function _getSPGNFTStorage() private pure returns (SPGNFTStorage storage $) {
        assembly {
            $.slot := SPGNFTStorageLocation
        }
    }

    // Check root ownership recursively
    function rootOwnerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenIdToOwner[tokenId].ownerAddress;
        return owner != address(0) ? owner : address(0);
    }

    function tokenOwnerOf(uint256 tokenId) external view override returns (address tokenOwner, uint256 parentTokenId, bool isParent) {
        tokenOwner = _tokenIdToOwner[tokenId].ownerAddress;
        parentTokenId = _tokenIdToOwner[tokenId].parentTokenId;
        isParent = parentTokenId > 0;
    }

    function transferToParent(address toContract, uint256 toTokenId, uint256 tokenId) external override onlyOwnerOrApproved(tokenId) {
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

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }


    function childTokensOfParent(address parentContract, uint256 parentTokenId) external view returns (uint256[] memory) {
        return _parentToChildTokens[parentContract][parentTokenId];
    }
}