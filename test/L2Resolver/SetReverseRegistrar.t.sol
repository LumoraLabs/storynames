// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {StoryResolver} from "src/contract/StoryResolver.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract SetReverseRegistrar is L2ResolverBase {
    function test_reverts_ifCalledByNonOwner(address caller, address newReverse) public {
        vm.assume(caller != owner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.prank(caller);
        resolver.setReverseRegistrar(newReverse);
    }

    function test_setsTheReverseRegistrarAccordingly(address newReverse) public {
        vm.expectEmit();
        emit StoryResolver.ReverseRegistrarUpdated(newReverse);
        vm.prank(owner);
        resolver.setReverseRegistrar(newReverse);
        assertEq(resolver.reverseRegistrar(), newReverse);
    }
}
