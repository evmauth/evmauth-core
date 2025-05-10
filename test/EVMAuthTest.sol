// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EVMAuth.sol";

contract EVMAuthTest is Test {
    // Test contract
    EVMAuth public token;

    // Test accounts
    address public owner;
    address public blacklistManager;
    address public financeManager;
    address public tokenManager;
    address public tokenMinter;
    address public tokenBurner;
    address public user1;
    address public user2;

    // Role identifiers
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant FINANCE_MANAGER_ROLE = keccak256("FINANCE_MANAGER_ROLE");
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
    bytes32 public constant TOKEN_BURNER_ROLE = keccak256("TOKEN_BURNER_ROLE");

    // Token IDs for testing
    uint256 public constant TOKEN_ID_0 = 0;
    uint256 public constant TOKEN_ID_1 = 1;

    // URIs for testing
    string public constant URI_1 = "https://www.radiustech.xyz/auth/1223953/token/{id}.json";
    string public constant URI_2 = "https://radiustech.xyz/auth/1223953/token/{id}.json";

    // Setup function that runs before each test
    function setUp() public {
        // Create test accounts
        owner = makeAddr("owner");
        blacklistManager = makeAddr("blacklistManager");
        financeManager = makeAddr("financeManager");
        tokenManager = makeAddr("tokenManager");
        tokenMinter = makeAddr("tokenMinter");
        tokenBurner = makeAddr("tokenBurner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy contract
        vm.startPrank(owner);
        token = new EVMAuth("EVMAuthTest", "1", URI_1, 60 * 60 * 24, owner);

        // Set up roles
        token.grantRole(BLACKLIST_MANAGER_ROLE, blacklistManager);
        token.grantRole(FINANCE_MANAGER_ROLE, financeManager);
        token.grantRole(TOKEN_MANAGER_ROLE, tokenManager);
        token.grantRole(TOKEN_MINTER_ROLE, tokenMinter);
        token.grantRole(TOKEN_BURNER_ROLE, tokenBurner);
        vm.stopPrank();
    }

    // Test constructor and initial state
    function test_Constructor() public view {
        assertEq(token.owner(), owner);
        assertEq(token.defaultAdmin(), owner);
        assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertEq(token.uri(TOKEN_ID_0), URI_1);
    }

    // Test role assignments
    function test_RoleAssignments() public view {
        assertTrue(token.hasRole(BLACKLIST_MANAGER_ROLE, owner));
        assertTrue(token.hasRole(BLACKLIST_MANAGER_ROLE, blacklistManager));
        assertTrue(token.hasRole(FINANCE_MANAGER_ROLE, owner));
        assertTrue(token.hasRole(FINANCE_MANAGER_ROLE, financeManager));
        assertTrue(token.hasRole(TOKEN_MANAGER_ROLE, owner));
        assertTrue(token.hasRole(TOKEN_MANAGER_ROLE, tokenManager));
        assertTrue(token.hasRole(TOKEN_MINTER_ROLE, owner));
        assertTrue(token.hasRole(TOKEN_MINTER_ROLE, tokenMinter));
        assertTrue(token.hasRole(TOKEN_BURNER_ROLE, owner));
        assertTrue(token.hasRole(TOKEN_BURNER_ROLE, tokenBurner));
    }

    // Test granting multiple roles at once
    function test_GrantRoles() public {
        // Create array of roles to grant
        bytes32[] memory rolesToGrant = new bytes32[](3);
        rolesToGrant[0] = TOKEN_MINTER_ROLE;
        rolesToGrant[1] = TOKEN_BURNER_ROLE;
        rolesToGrant[2] = TOKEN_MANAGER_ROLE;

        // Grant multiple roles to user1
        vm.prank(owner);
        token.grantRoles(rolesToGrant, user1);

        // Verify all roles were granted
        assertTrue(token.hasRole(TOKEN_MINTER_ROLE, user1));
        assertTrue(token.hasRole(TOKEN_BURNER_ROLE, user1));
        assertTrue(token.hasRole(TOKEN_MANAGER_ROLE, user1));

        // Verify DEFAULT_ADMIN_ROLE was not granted (should be skipped)
        assertFalse(token.hasRole(DEFAULT_ADMIN_ROLE, user1));
    }

    // Test revoking multiple roles at once
    function test_RevokeRoles() public {
        // First grant multiple roles to user1
        vm.startPrank(owner);
        token.grantRole(TOKEN_MINTER_ROLE, user1);
        token.grantRole(TOKEN_BURNER_ROLE, user1);
        token.grantRole(TOKEN_MANAGER_ROLE, user1);
        vm.stopPrank();

        // Verify roles were granted
        assertTrue(token.hasRole(TOKEN_MINTER_ROLE, user1));
        assertTrue(token.hasRole(TOKEN_BURNER_ROLE, user1));
        assertTrue(token.hasRole(TOKEN_MANAGER_ROLE, user1));

        // Create array of roles to revoke
        bytes32[] memory rolesToRevoke = new bytes32[](3);
        rolesToRevoke[0] = TOKEN_MINTER_ROLE;
        rolesToRevoke[1] = TOKEN_BURNER_ROLE;
        rolesToRevoke[2] = TOKEN_MANAGER_ROLE;

        // Revoke all roles at once
        vm.prank(owner);
        token.revokeRoles(rolesToRevoke, user1);

        // Verify all roles were revoked
        assertFalse(token.hasRole(TOKEN_MINTER_ROLE, user1));
        assertFalse(token.hasRole(TOKEN_BURNER_ROLE, user1));
        assertFalse(token.hasRole(TOKEN_MANAGER_ROLE, user1));
    }

    // Test that granting roles to blacklisted accounts fails
    function test_GrantRolesToBlacklistedAccount() public {
        // Blacklist user1
        vm.prank(blacklistManager);
        token.addToBlacklist(user1);

        // Create array of roles to grant
        bytes32[] memory rolesToGrant = new bytes32[](2);
        rolesToGrant[0] = TOKEN_MINTER_ROLE;
        rolesToGrant[1] = TOKEN_BURNER_ROLE;

        // Attempt to grant roles to blacklisted user (should fail)
        vm.expectRevert("Account is blacklisted");
        vm.prank(owner);
        token.grantRoles(rolesToGrant, user1);

        // Verify no roles were granted
        assertFalse(token.hasRole(TOKEN_MINTER_ROLE, user1));
        assertFalse(token.hasRole(TOKEN_BURNER_ROLE, user1));
    }

    // Test that only DEFAULT_ADMIN_ROLE can grant/revoke multiple roles
    function test_UnauthorizedRolesAccess() public {
        // Create arrays for roles
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = TOKEN_MINTER_ROLE;
        roles[1] = TOKEN_BURNER_ROLE;

        // Attempt to grant roles as non-admin (should fail)
        vm.expectRevert();
        vm.prank(user1);
        token.grantRoles(roles, user2);

        // Attempt to revoke roles as non-admin (should fail)
        vm.expectRevert();
        vm.prank(user1);
        token.revokeRoles(roles, tokenMinter);
    }

    // Test setting URI
    function test_SetURI() public {
        // Try as non-manager (should fail)
        vm.expectRevert();
        vm.prank(user1);
        token.setURI(URI_2);

        // Try as token manager (should succeed)
        vm.prank(tokenManager);
        token.setURI(URI_2);

        assertEq(token.uri(TOKEN_ID_0), URI_2);
    }

    // Test setting metadata
    function test_SetMetadata() public {
        // Set metadata as token manager
        vm.startPrank(tokenManager);

        // For TOKEN_ID_0, set all properties (note: no FINANCE_MANAGER_ROLE, so price won't be set)
        token.setMetadata(TOKEN_ID_0, true, true, true, 100, 3600);
        vm.stopPrank();

        // Check token properties
        assertTrue(token.active(TOKEN_ID_0));
        assertTrue(token.burnable(TOKEN_ID_0));
        assertTrue(token.transferable(TOKEN_ID_0));
        assertEq(token.priceOf(TOKEN_ID_0), 0); // Should still be 0 (tokenManager is not FINANCE_MANAGER_ROLE)
        assertEq(token.ttlOf(TOKEN_ID_0), 3600); // TTL should be set as token is burnable

        // Now set metadata with both TOKEN_MANAGER_ROLE and FINANCE_MANAGER_ROLE
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        vm.prank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 200, 7200);

        // Check price has been updated
        assertEq(token.priceOf(TOKEN_ID_0), 200);
        assertEq(token.ttlOf(TOKEN_ID_0), 7200);
    }

    // Test getting metadata
    function test_GetMetadata() public {
        // Grant tokenManager the FINANCE_MANAGER_ROLE role
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        // Set metadata as token manager
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 100, 3600);
        vm.stopPrank();

        // Get metadata
        EVMAuth.TokenMetadata memory metadata = token.metadataOf(TOKEN_ID_0);

        // Check metadata properties
        assertEq(metadata.id, TOKEN_ID_0);
        assertTrue(metadata.active);
        assertTrue(metadata.burnable);
        assertTrue(metadata.transferable);
        assertEq(metadata.price, 100);
        assertEq(metadata.ttl, 3600);
    }

    // Test token issuing
    function test_IssueToken() public {
        // Set up token metadata first
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0, 0);
        vm.stopPrank();

        // Issue token to user1
        vm.startPrank(tokenMinter);
        token.issue(user1, TOKEN_ID_0, 1, "");
        vm.stopPrank();

        // Check token balance
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 1);
    }

    // Test batch issuing
    function test_IssueBatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_0;
        ids[1] = TOKEN_ID_1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 10;

        // Set up token metadata first
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0, 0);
        token.setMetadata(TOKEN_ID_1, true, true, true, 0, 0);
        vm.stopPrank();

        // Issue tokens in batch
        vm.startPrank(tokenMinter);
        token.issueBatch(user1, ids, amounts, "");
        vm.stopPrank();

        // Check token balances
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 5);
        assertEq(token.balanceOf(user1, TOKEN_ID_1), 10);
    }

    // Test token transfer
    function test_TokenTransfer() public {
        // Set up token metadata first (make it transferable)
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0, 0);
        vm.stopPrank();

        // Issue token to user1
        vm.startPrank(tokenMinter);
        token.issue(user1, TOKEN_ID_0, 1, "");
        vm.stopPrank();

        // Transfer from user1 to user2
        vm.prank(user1);
        token.safeTransferFrom(user1, user2, TOKEN_ID_0, 1, "");

        // Check token balances
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 0);
        assertEq(token.balanceOf(user2, TOKEN_ID_0), 1);
    }

    // Test non-transferable token
    function test_NonTransferableToken() public {
        // Set up token metadata (not transferable)
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, false, 0, 0);
        vm.stopPrank();

        // Issue token to user1
        vm.startPrank(tokenMinter);
        token.issue(user1, TOKEN_ID_0, 1, "");
        vm.stopPrank();

        // Try to transfer from user1 to user2 (should fail)
        vm.expectRevert();
        vm.prank(user1);
        token.safeTransferFrom(user1, user2, TOKEN_ID_0, 1, "");
    }

    // Test token purchase
    function test_TokenPurchase() public {
        // Grant FINANCE_MANAGER_ROLE to tokenManager, to allow price setting via setMetadata
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        // Set up token metadata with price
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0.1 ether, 0);
        vm.stopPrank();

        // Purchase token as user1
        vm.deal(user1, 1 ether); // Give user1 some ETH
        vm.prank(user1);
        token.purchase{value: 0.1 ether}(user1, TOKEN_ID_0, 1);

        // Check token balance
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 1);
    }

    // Test token purchase with insufficient funds
    function test_TokenPurchaseInsufficientFunds() public {
        // Grant FINANCE_MANAGER_ROLE to tokenManager, to allow price setting via setMetadata
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        // Set up token metadata with price
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0.1 ether, 0);
        vm.stopPrank();

        // Try to purchase token with insufficient funds
        vm.deal(user1, 0.05 ether); // Give user1 some ETH, but not enough
        vm.expectRevert();
        vm.prank(user1);
        token.purchase{value: 0.05 ether}(user1, TOKEN_ID_0, 1);
    }

    // Test token purchase for a different account
    function test_TokenPurchaseDifferentAccount() public {
        // Grant FINANCE_MANAGER_ROLE to tokenManager, to allow price setting via setMetadata
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        // Set up token metadata with price
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0.1 ether, 0);
        vm.stopPrank();

        // Purchase token for user2 as user1
        vm.deal(user1, 1 ether); // Give user1 some ETH
        vm.prank(user1);
        token.purchase{value: 0.1 ether}(user2, TOKEN_ID_0, 1);

        // Check token balance
        assertEq(token.balanceOf(user2, TOKEN_ID_0), 1);
    }

    // Test token purchase for a different account with overpayment (sender should get refund)
    function test_TokenPurchaseDifferentAccountOverpayment() public {
        // Grant FINANCE_MANAGER_ROLE to tokenManager, to allow price setting via setMetadata
        vm.startPrank(owner);
        token.grantRole(FINANCE_MANAGER_ROLE, tokenManager);
        vm.stopPrank();

        // Set up token metadata with price
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0.1 ether, 0);
        vm.stopPrank();

        // Purchase token for user2 as user1 with overpayment
        vm.deal(user1, 1 ether); // Give user1 some ETH
        vm.prank(user1);
        (bool success,) = address(token).call{value: 0.2 ether}(
            abi.encodeWithSignature("purchase(address,uint256,uint256)", user2, TOKEN_ID_0, 1)
        );

        // Check that the purchase was successful and user1 got a refund
        assertTrue(success);
        assertEq(token.balanceOf(user2, TOKEN_ID_0), 1);

        // Confirm user1 got a refund
        assertEq(address(user1).balance, 0.9 ether); // 1 ether - 0.1 ether (purchase) = 0.9 ether
        assertEq(address(user2).balance, 0 ether); // user2 should have 0 ether
    }

    // Test token with expiration
    function test_TokenExpiration() public {
        // Set up token metadata with 1 hour TTL
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0, 3600);
        vm.stopPrank();

        // Issue token to user1
        vm.startPrank(tokenMinter);
        token.issue(user1, TOKEN_ID_0, 1, "");
        vm.stopPrank();

        // Check token balance immediately
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 1);

        // Fast forward time by 2 hours (past expiration)
        vm.warp(block.timestamp + 7200);

        // Check token balance again - should be 0 after burning the expired token
        // (Note: In reality, the token isn't automatically burned until some action triggers it,
        // but balanceOf should still return 0 for expired tokens)
        assertEq(token.balanceOf(user1, TOKEN_ID_0), 0);
    }

    // Test blacklisting
    function test_Blacklisting() public {
        // Set up token metadata first
        vm.startPrank(tokenManager);
        token.setMetadata(TOKEN_ID_0, true, true, true, 0, 0);
        vm.stopPrank();

        // Issue token to user1
        vm.startPrank(tokenMinter);
        token.issue(user1, TOKEN_ID_0, 1, "");
        vm.stopPrank();

        // Blacklist user1
        vm.prank(blacklistManager);
        token.addToBlacklist(user1);

        // Check if user1 is blacklisted
        assertTrue(token.isBlacklisted(user1));

        // User1 should not be able to transfer tokens
        vm.expectRevert();
        vm.prank(user1);
        token.safeTransferFrom(user1, user2, TOKEN_ID_0, 1, "");
    }

    // Test batch blacklisting
    function test_BatchBlacklisting() public {
        // Create array of addresses to blacklist
        address[] memory blacklistAddresses = new address[](2);
        blacklistAddresses[0] = user1;
        blacklistAddresses[1] = user2;

        // Blacklist the addresses
        vm.prank(blacklistManager);
        token.addBatchToBlacklist(blacklistAddresses);

        // Check if both addresses are blacklisted
        assertTrue(token.isBlacklisted(user1));
        assertTrue(token.isBlacklisted(user2));
    }

    // Test removing from blacklist
    function test_RemoveFromBlacklist() public {
        // Blacklist user1
        vm.prank(blacklistManager);
        token.addToBlacklist(user1);

        // Check if user1 is blacklisted
        assertTrue(token.isBlacklisted(user1));

        // Remove user1 from blacklist
        vm.prank(blacklistManager);
        token.removeFromBlacklist(user1);

        // Check if user1 is no longer blacklisted
        assertFalse(token.isBlacklisted(user1));
    }

    // Test that the contract does not accept direct ETH transfers
    function test_RejectDirectPayment() public {
        // Send user1 some ETH
        vm.deal(user1, 1 ether);

        // Try to send ETH directly to contract (should fail)
        vm.prank(user1);
        (bool success,) = address(token).call{value: 0.1 ether}("");

        // Assert that the transfer failed
        assertFalse(success);

        // Check that no ETH was transferred
        assertEq(address(token).balance, 0);
        assertEq(address(user1).balance, 1 ether);
    }

    // Test changing default admin
    function test_ChangeDefaultAdmin() public {
        // Begin admin transfer
        vm.prank(owner);
        token.beginDefaultAdminTransfer(user1);

        // Get admin transfer schedule
        (address newAdmin, uint48 schedule) = token.pendingDefaultAdmin();
        assertEq(newAdmin, user1);

        // Fast forward past the delay
        vm.warp(schedule + 1);

        // Accept the transfer
        vm.prank(user1);
        token.acceptDefaultAdminTransfer();

        // Check the new admin
        assertEq(token.defaultAdmin(), user1);
    }
}
