// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {L2ResolverBase} from "./L2ResolverBase.t.sol";
import {StoryResolver} from "src/contract/StoryResolver.sol";

contract SetApprovalForAll is L2ResolverBase {
    function test_revertsIfCalledForSelf() public {
        vm.expectRevert(StoryResolver.CantSetSelfAsOperator.selector);
        vm.prank(user);
        resolver.setApprovalForAll(user, true);
    }

    function test_allowsSenderToSetApproval(address operator) public {
        vm.assume(operator != user);
        vm.expectEmit(address(resolver));
        emit StoryResolver.ApprovalForAll(user, operator, true);
        vm.prank(user);
        resolver.setApprovalForAll(operator, true);
        assertTrue(resolver.isApprovedForAll(user, operator));
    }
}
