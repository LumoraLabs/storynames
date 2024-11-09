// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ComposableSPG.sol";
import "../interface/ISPGNFT.sol";

contract ComposableSPGFactory is Ownable {
    UpgradeableBeacon public immutable beacon;
    address[] public allComposableSPGProxies;

    /// @notice Initializes the factory by deploying the beacon with the implementation address.
    constructor(
        address derivativeWorkflows,
        address groupingWorkflows,
        address licenseAttachmentWorkflows,
        address registrationWorkflows,
        address storynameContract
    ) Ownable(msg.sender) {
        // Deploy the implementation of ComposableSPG
        ComposableSPG composableSPGImplementation = new ComposableSPG(
            derivativeWorkflows,
            groupingWorkflows,
            licenseAttachmentWorkflows,
            registrationWorkflows,
            storynameContract
        );
        // Deploy the beacon and set the initial implementation and beacon owner
        beacon = new UpgradeableBeacon(address(composableSPGImplementation), msg.sender);
    }

    /// @notice Deploys a new upgradeable instance of ComposableSPG with specified initialization parameters.
    /// @param initParams The initialization parameters for the new instance. See {ISPGNFT.InitParams}
    /// @return proxyAddress The address of the newly deployed proxy contract.
    function createComposableSPG(ISPGNFT.InitParams calldata initParams) external onlyOwner returns (address proxyAddress) {
        // Encode the initializer function call with the provided initialization parameters
        bytes memory data = abi.encodeWithSelector(
            ComposableSPG.initialize.selector,
            initParams
        );

        // Deploy a new BeaconProxy pointing to the beacon
        BeaconProxy proxy = new BeaconProxy(address(beacon), data);
        proxyAddress = address(proxy);
        allComposableSPGProxies.push(proxyAddress);

        emit ComposableSPGCreated(proxyAddress, initParams.name, initParams.symbol, initParams.contractURI);
    }

    /// @notice Returns the total number of deployed ComposableSPG proxies.
    function getProxiesCount() external view returns (uint256) {
        return allComposableSPGProxies.length;
    }

    /// @notice Gets the proxy address at a specific index.
    /// @param index The index of the proxy in the array.
    /// @return The address of the proxy.
    function getProxyAddress(uint256 index) external view returns (address) {
        require(index < allComposableSPGProxies.length, "Index out of bounds");
        return allComposableSPGProxies[index];
    }

    /// @notice Emitted when a new ComposableSPG proxy is created.
    event ComposableSPGCreated(address indexed proxyAddress, string name, string symbol, string contractURI);
}
