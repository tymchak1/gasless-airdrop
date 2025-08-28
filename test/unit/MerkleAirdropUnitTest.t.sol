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

    function testClaimWithPermit() public {
        token.mint(address(airdrop), AMOUNT_TO_SEND);

        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                address(airdrop),
                AMOUNT_TO_CLAIM,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(user);
        airdrop.claimWithPermit(user, AMOUNT_TO_CLAIM, PROOF, deadline, v, r, s);

        assertEq(token.balanceOf(user), AMOUNT_TO_CLAIM);
        assertTrue(airdrop.s_hasClaimed(user));
    }

    function testClaimTwiceReverts() public {
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                address(airdrop),
                AMOUNT_TO_CLAIM,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        // перший клейм
        vm.prank(user);
        airdrop.claimWithPermit(user, AMOUNT_TO_CLAIM, PROOF, deadline, v, r, s);

        // другий клейм має впасти
        vm.prank(user);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claimWithPermit(user, AMOUNT_TO_CLAIM, PROOF, deadline, v, r, s);
    }

    function testClaimRevertsWithInvalidProof() public {
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user,
                address(airdrop),
                AMOUNT_TO_CLAIM,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256("wrong");

        vm.prank(user);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        airdrop.claimWithPermit(user, AMOUNT_TO_CLAIM, badProof, deadline, v, r, s);
    }

    /*//////////////////////////////////////////////////////////////
                           GETTER TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetMerkleRoot() public view {
        assertEq(airdrop.getMerkleRoot(), ROOT);
    }

    function testGetAirdropToken() public view {
        assertEq(address(airdrop.getAirdropToken()), address(token));
    }
}
