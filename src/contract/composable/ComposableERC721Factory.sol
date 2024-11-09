// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ComposableERC721.sol";

contract ComposableERC721Factory is Ownable {
    UpgradeableBeacon public immutable beacon;
    address[] public allComposableERC721Proxies;

    /// @notice Initializes the factory by deploying the beacon with the implementation address.
    constructor() Ownable(msg.sender) {
        // Deploy the implementation of ComposableERC721
        ComposableERC721 composableERC721Implementation = new ComposableERC721();
        // Deploy the beacon and set the initial implementation and beacon owner
        beacon = new UpgradeableBeacon(address(composableERC721Implementation), msg.sender);
    }

    /// @notice Deploys a new upgradeable instance of ComposableERC721.
    /// @param name The name of the token collection.
    /// @param symbol The symbol of the token collection.
    /// @param contractURI The URI with metadata about the contract.
    /// @return proxyAddress The address of the newly deployed proxy contract.
    function createComposableERC721(
        string memory name,
        string memory symbol,
        string memory contractURI, 
        address owner
    ) external onlyOwner returns (address proxyAddress) {
        // Encode the initializer function call with the provided parameters
        bytes memory data = abi.encodeWithSelector(
            ComposableERC721.initialize.selector,
            name,
            symbol,
            contractURI,
            owner
        );

        // Deploy a new BeaconProxy pointing to the beacon
        BeaconProxy proxy = new BeaconProxy(address(beacon), data);
        proxyAddress = address(proxy);
        allComposableERC721Proxies.push(proxyAddress);

        emit ComposableERC721Created(proxyAddress, name, symbol, contractURI);
    }

    /// @notice Returns the total number of deployed ComposableERC721 proxies.
    function getProxiesCount() external view returns (uint256) {
        return allComposableERC721Proxies.length;
    }

    /// @notice Gets the proxy address at a specific index.
    /// @param index The index of the proxy in the array.
    /// @return The address of the proxy.
    function getProxyAddress(uint256 index) external view returns (address) {
        require(index < allComposableERC721Proxies.length, "Index out of bounds");
        return allComposableERC721Proxies[index];
    }

    /// @notice Emitted when a new ComposableERC721 proxy is created.
    event ComposableERC721Created(address indexed proxyAddress, string name, string symbol, string contractURI);
}
