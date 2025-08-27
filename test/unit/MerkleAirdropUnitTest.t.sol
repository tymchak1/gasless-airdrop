// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../../src/Token.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";

contract MerkleAirdropUnitTest is Test {
    Token token;
    MerkleAirdrop airdrop;

    bytes32 constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [proof1, proof2];
    address gasPayer;
    address user;
    uint256 userPrivKey;

    function setUp() public {
        token = new Token();
        airdrop = new MerkleAirdrop(ROOT, token);
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructorRevertsIfMerkleRootIsZero() public {
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidMerkleRoot.selector);
        new MerkleAirdrop(bytes32(0), token);
    }

    function testConstructorRevertsIfTokenAddressIsZero() public {
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidTokenAddress.selector);
        new MerkleAirdrop(ROOT, Token(address(0)));
    }

    function testConstructorSetsMerkleRootAndToken() public view {
        assertEq(airdrop.getMerkleRoot(), ROOT);
        assertEq(address(airdrop.getAirdropToken()), address(token));
    }
    /*//////////////////////////////////////////////////////////////
                           CLAIM TESTS
    //////////////////////////////////////////////////////////////*/

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
