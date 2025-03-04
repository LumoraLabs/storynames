//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StoryRegistrar} from "src/contract/StoryRegistrar.sol";
import {BaseRegistrarBase} from "./BaseRegistrarBase.t.sol";
import {ERC721} from "lib/solady/src/tokens/ERC721.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BASE_ETH_NODE, GRACE_PERIOD} from "src/util/Constants.sol";

contract Register is BaseRegistrarBase {
    function test_reverts_whenTheRegistrarIsNotLive() public {
        vm.prank(address(baseRegistrar));
        registry.setOwner(BASE_ETH_NODE, owner);
        vm.expectRevert(StoryRegistrar.RegistrarNotLive.selector);
        baseRegistrar.register(id, user, duration);
    }

    function test_reverts_whenCalledByNonController(address caller) public {
        vm.prank(caller);
        vm.expectRevert(StoryRegistrar.OnlyController.selector);
        baseRegistrar.register(id, user, duration);
    }

    function test_successfullyRegisters() public {
        _registrationSetup();

        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), user, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), user);
        vm.expectEmit(address(baseRegistrar));
        emit StoryRegistrar.NameRegistered(id, user, duration + blockTimestamp);

        vm.warp(blockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.register(id, user, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == user);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_successfullyRegisters_afterExpiry(address newOwner) public {
        vm.assume(newOwner != user && newOwner != address(0));
        _registrationSetup();
        _registerName(label, user, duration);

        uint256 newBlockTimestamp = blockTimestamp + duration + GRACE_PERIOD + 1;
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(user, address(0), id); // on _burn(id)
        vm.expectEmit(address(baseRegistrar));
        emit ERC721.Transfer(address(0), newOwner, id);
        vm.expectEmit(address(registry));
        emit ENS.NewOwner(BASE_ETH_NODE, bytes32(id), newOwner);
        vm.expectEmit(address(baseRegistrar));
        emit StoryRegistrar.NameRegistered(id, newOwner, duration + newBlockTimestamp);

        vm.warp(newBlockTimestamp);
        vm.prank(controller);
        uint256 expires = baseRegistrar.register(id, newOwner, duration);

        address ownerOfToken = baseRegistrar.ownerOf(id);
        assertTrue(ownerOfToken == newOwner);
        assertTrue(baseRegistrar.nameExpires(id) == expires);
    }

    function test_reverts_ifTheNameIsNotAvailable(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(StoryRegistrar.NotAvailable.selector, id));
        vm.prank(controller);
        baseRegistrar.register(id, newOwner, duration);
    }

    function test_reverts_ifTheNameIsNotAvailable_duringGracePeriod(address newOwner) public {
        vm.assume(newOwner != user);
        _registrationSetup();
        _registerName(label, user, duration);

        vm.expectRevert(abi.encodeWithSelector(StoryRegistrar.NotAvailable.selector, id));
        vm.warp(blockTimestamp + duration + GRACE_PERIOD - 1);
        vm.prank(controller);
        baseRegistrar.register(id, newOwner, duration);
    }
}
