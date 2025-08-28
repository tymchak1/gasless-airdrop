// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address owner = address(this);
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new Token();
    }

    function testInitialSupplyIsZero() public view {
        assertEq(token.totalSupply(), 0);
    }

    function testMintIncreasesBalanceAndSupply() public {
        token.mint(alice, 100e18);
        assertEq(token.balanceOf(alice), 100e18);
        assertEq(token.totalSupply(), 100e18);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(bob);
        vm.expectRevert();
        token.mint(alice, 100e18);
    }

    function testPermitSignature() public {
        uint256 privateKey = 0xA11CE;
        address signer = vm.addr(privateKey);

        uint256 value = 100e18;
        uint256 nonce = token.nonces(signer);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 digest = token.DOMAIN_SEPARATOR();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    digest,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            signer,
                            bob,
                            value,
                            nonce,
                            deadline
                        )
                    )
                )
            )
        );

        token.permit(signer, bob, value, deadline, v, r, s);
        assertEq(token.allowance(signer, bob), value);
    }
}
