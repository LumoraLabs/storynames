// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.23;

// import "forge-std/Test.sol";
// import "src/ComposableERC721.sol";
// import "src/interfaces/ISPGNFT.sol";
// import "src/lib/Errors.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract ComposableERC721Test is Test {
//     ComposableERC721 public composableERC721;
//     address public owner = address(0x123);
//     address public minter = address(0x456);
//     address public user = address(0x789);
//     address public mintFeeToken = address(new IERC20()); // Mock ERC20 token for testing

//     function setUp() public {
//         // Deploy the contract with mock addresses for periphery contracts
//         composableERC721 = new ComposableERC721(
//             address(0xabc), // DERIVATIVE_WORKFLOWS_ADDRESS
//             address(0xdef), // GROUPING_WORKFLOWS_ADDRESS
//             address(0xghi), // LICENSE_ATTACHMENT_WORKFLOWS_ADDRESS
//             address(0xjkl)  // REGISTRATION_WORKFLOWS_ADDRESS
//         );

//         // Initialize the contract with the required parameters
//         ISPGNFT.InitParams memory initParams = ISPGNFT.InitParams({
//             owner: owner,
//             maxSupply: 1000,
//             mintFee: 1 ether,
//             mintFeeToken: mintFeeToken,
//             mintFeeRecipient: owner,
//             mintOpen: true,
//             isPublicMinting: false,
//             baseURI: "https://example.com/",
//             contractURI: "https://example.com/contract"
//         });

//         vm.prank(owner);
//         composableERC721.initialize(initParams);
//     }

//     function test_initialization() public {
//         // Check initialization values
//         assertEq(composableERC721.totalSupply(), 0);
//         assertEq(composableERC721.mintFee(), 1 ether);
//         assertEq(composableERC721.mintFeeToken(), mintFeeToken);
//         assertEq(composableERC721.mintFeeRecipient(), owner);
//         assertTrue(composableERC721.mintOpen());
//     }

//     function test_mintByPeriphery() public {
//         string memory nftMetadataURI = "https://example.com/metadata.json";
//         bytes32 nftMetadataHash = keccak256(abi.encodePacked(nftMetadataURI));

//         vm.prank(address(0xabc)); // DERIVATIVE_WORKFLOWS_ADDRESS as periphery
//         uint256 tokenId = composableERC721.mintByPeriphery(user, address(0xabc), nftMetadataURI, nftMetadataHash, true);

//         // Verify the minted token
//         assertEq(composableERC721.ownerOf(tokenId), user);
//         assertEq(composableERC721.totalSupply(), 1);
//     }

//     function test_nonPeripheryCannotMint() public {
//         string memory nftMetadataURI = "https://example.com/metadata.json";
//         bytes32 nftMetadataHash = keccak256(abi.encodePacked(nftMetadataURI));

//         vm.prank(user); // Attempting to mint from a non-periphery address
//         vm.expectRevert(Errors.SPGNFT__CallerNotPeripheryContract.selector);
//         composableERC721.mintByPeriphery(user, user, nftMetadataURI, nftMetadataHash, true);
//     }

//     function test_parentChildTokenTransfer() public {
//         // Mint a parent token and a child token
//         string memory nftMetadataURI1 = "https://example.com/meta1.json";
//         string memory nftMetadataURI2 = "https://example.com/meta2.json";
//         vm.prank(address(0xabc));
//         uint256 parentTokenId = composableERC721.mintByPeriphery(user, address(0xabc), nftMetadataURI1, keccak256(bytes(nftMetadataURI1)), true);
//         vm.prank(address(0xabc));
//         uint256 childTokenId = composableERC721.mintByPeriphery(user, address(0xabc), nftMetadataURI2, keccak256(bytes(nftMetadataURI2)), true);

//         // Transfer child token to parent token
//         vm.prank(user);
//         composableERC721.transferToParent(address(composableERC721), parentTokenId, childTokenId);

//         // Verify ownership and hierarchy
//         (address tokenOwner, uint256 parentId, bool isParent) = composableERC721.tokenOwnerOf(childTokenId);
//         assertEq(tokenOwner, address(composableERC721));
//         assertEq(parentId, parentTokenId);
//         assertTrue(isParent);
//     }

//     function test_setMintFeeAndRecipient() public {
//         address newRecipient = address(0x999);

//         // Only the owner can set the mint fee and recipient
//         vm.prank(owner);
//         composableERC721.setMintFee(2 ether);
//         assertEq(composableERC721.mintFee(), 2 ether);

//         vm.prank(owner);
//         composableERC721.setMintFeeRecipient(newRecipient);
//         assertEq(composableERC721.mintFeeRecipient(), newRecipient);
//     }

//     function test_revertUnauthorizedMintFeeChange() public {
//         vm.prank(user); // Non-owner attempts to set mint fee recipient
//         vm.expectRevert(Errors.SPGNFT__CallerNotFeeRecipient.selector);
//         composableERC721.setMintFeeRecipient(user);
//     }

//     function test_withdrawToken() public {
//         // Mock balance in the contract for ERC20 token
//         vm.deal(mintFeeToken, address(composableERC721), 100 ether);

//         // Withdraw the token balance
//         vm.prank(owner);
//         composableERC721.withdrawToken(mintFeeToken);

//         // Check the recipient received the balance
//         assertEq(IERC20(mintFeeToken).balanceOf(owner), 100 ether);
//     }

//     function test_setBaseURI() public {
//         string memory newBaseURI = "https://newbase.com/";

//         vm.prank(owner);
//         composableERC721.setBaseURI(newBaseURI);

//         // Verify that the base URI is updated
//         assertEq(composableERC721.baseURI(), newBaseURI);
//     }

//     function test_revertNonOwnerSetBaseURI() public {
//         string memory newBaseURI = "https://newbase.com/";

//         vm.prank(user); // Non-owner attempts to set the base URI
//         vm.expectRevert("AccessControl: caller is not the owner"); // Adjust with the expected revert reason if necessary
//         composableERC721.setBaseURI(newBaseURI);
//     }
// }
