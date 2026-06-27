# Soulbound Credentials

> Non-transferable on-chain credentials with ZK verification

Soulbound Credentials enables the issuance and verification of non-transferable digital credentials on the blockchain. Using zero-knowledge proofs, holders can prove ownership and attribute validity without revealing underlying personal data. Credentials are permanently bound to wallet addresses and cannot be bought, sold, or transferred.

## On-Chain Proof (Deployed & Verified)

### Base Sepolia (OP Stack)

| Contract | Address | Tx Hash |
|----------|---------|--------|
| **SoulboundToken** | [`0x473B...f78A`](https://sepolia.basescan.org/address/0x473B60ceE81EEa934cAF8B83c75EC80f5d91f78A) | [`0xd773...6ee6`](https://sepolia.basescan.org/tx/0xd773ca916624f4f9fbde9a3a84081aa9d1badaced187831f388070f3170a6ee6) |
| **CredentialRegistry** | [`0xdD56...F14d`](https://sepolia.basescan.org/address/0xdD56cC6795e7B4088AAB358831400244B066F14d) | [`0xbef8...92c4`](https://sepolia.basescan.org/tx/0xbef8a8e2d47e344c4f1fa957bfe2f70e946cc4428db279c56bc68ba55e5992c4) |

**Deployer**: [`0x7F75...C739`](https://sepolia.basescan.org/address/0x7F75bfAfeD5c96584774c7F2Bc33F3bF887BC739) | **Network**: Base Sepolia
## How It Works

1. **Issuance**: Trusted issuers mint soulbound credentials to a recipient's wallet address. Each credential encodes attributes (e.g., identity, certifications, memberships) as on-chain data.

2. **Non-Transferability**: Credentials are bound to the recipient's address via smart contract logic. Transfer functions are disabled, ensuring credentials cannot be moved between wallets.

3. **ZK Verification**: Holders generate zero-knowledge proofs to verify credential attributes without exposing raw data. For example, prove "I am over 18" without revealing your birthdate.

4. **Revocation**: Issuers can revoke credentials if they are expired, invalidated, or compromised. Revocation status is checked on-chain in real time.

5. **Discovery**: A decentralized registry allows verifiers to query credential schemas and issuer reputations without relying on a centralized directory.

## Smart Contracts

```
contracts/
├── SoulboundCredential.sol        # ERC-721 variant with non-transferable logic
├── CredentialRegistry.sol         # Schema registry and issuer management
├── ZKVerifier.sol                 # Groth16/PLONK proof verification
├── AttributeOracle.sol            # External attribute validation
├── RevocationManager.sol          # Credential revocation logic
├── interfaces/
│   ├── ICredential.sol
│   └── IVerifier.sol
└── libraries/
    ├── ProofLib.sol
    └── SchemaLib.sol
```

### Key Features

- **ERC-721 SBT Extension**: Soulbound tokens extend ERC-721 with transfer restrictions enforced at the contract level.
- **Schema Registry**: Credential schemas are registered on-chain, enabling standardized verification across dApps.
- **ZK-SNARK Integration**: Groth16 and PLONK proof systems are supported for privacy-preserving attribute verification.
- **Revocation List**: On-chain revocation status ensures credentials can be invalidated in real time.
- **Gas Optimization**: Batch minting and merkle tree–based revocation reduce gas costs.

## Setup

### Prerequisites

- Node.js >= 18
- Foundry or Hardhat
- Wallet with testnet ETH

### Installation

```bash
git clone https://github.com/Souravjoy7/soulbound-credentials.git
cd soulbound-credentials
npm install
```

### Compile

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy (Testnet)

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Environment Variables

```
RPC_URL=<your-rpc-url>
PRIVATE_KEY=<your-deployer-key>
ETHERSCAN_API_KEY=<your-etherscan-key>
```

## License

MIT License. See [LICENSE](LICENSE) for details.
