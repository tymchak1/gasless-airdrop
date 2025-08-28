# Merkle Airdrop

## Description
Merkle Airdrop is a Solidity smart contract that allows token airdrops using a Merkle Tree for efficient verification of user entitlements. The contract supports gasless claims via EIP-2612 `permit`.

## Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/merkle-airdrop.git
cd merkle-airdrop
```
2. Install dependencies:
```bash
forge install
```

## Deployment
Use Foundry for local and test deployment:
```bash
forge script script/Deployer.s.sol --fork-url <RPC_URL> --broadcast
```

## Usage
1. Create a Merkle Tree with users and amounts.
2. Use the `MakeMerkle.s.sol` script to generate the root and proof.
3. Users can claim tokens:
```solidity
airdrop.claimWithPermit(user, amount, proof, deadline, v, r, s);
```

## Tests
Run unit tests:
```bash
forge test
```
Tests cover:
- `Token.sol` (ERC20 + permit)
- `MerkleAirdrop.sol` (claim, proof verification, permit, getters)
- Scripts can be run integratively locally.