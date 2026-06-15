# StableGen Token Contracts

## Intro

This is the **main repository** for StableGen's smart contracts. It is the canonical home for the StableGen contract framework—the shared on-chain architecture used to issue and operate **asset reference tokens (ARTs)** that represent exposure to real-world assets.

Asset reference tokens under this framework share a common design:  
 - ERC20-based issuance, 
 - oracle-driven pricing, 
 - role-based administration, 
 - compliance controls (such as KYC and address freezing), 
 - and optional extensions for gas-abstracted transfers and cross-chain movement. 
 
 Each token is configured for its underlying asset (feeds, reserve checks, fees, and redemption paths), but builds on the same contract patterns and supporting libraries published here.

The repository includes:

1. **StableGold**: the first asset reference token in the framework—a gold-backed ERC20. 

As StableGen issues additional asset reference tokens, their production contracts, interfaces, and shared modules will be added to this repository.

Source code is published for third-party review, integration, and fork. Deployment addresses, supported networks, and operational runbooks are maintained separately.

## Contract Specification

StableGold represents tokenized gold exposure on Ethereum-compatible networks. Holders can interact with the token through standard ERC20 transfers, while authorized flows support:

- **Minting and supply caps** — role-gated minting with optional proof-of-reserve enforcement
- **Primary purchase (`buy`)** — mint tokens against accepted stablecoins using a live gold price feed
- **Redemption** — physical redemption (burn or transfer to dead address) or OTC buyback
- **On-chain buyback** — sell StableGold back for accepted stablecoins at a feed-derived price minus fees
- **Compliance** — KYC gating, address freezing, and pausability
- **EIP-3009** — gas-abstracted transfers via signed authorizations
- **Cross-chain (IERC7802)** — mint/burn hooks for a designated token bridge

## Architecture

At a high level, the system separates the **token**, **pricing/reserve oracles**, and **supporting libraries**:

```text
┌─────────────────────────────────────────────────────────────┐
│                      StableGold (ERC20)                     │
│  roles · pause · KYC/freeze · buy · redeem · onchain BB     │
│  EIP-3009 · IERC7802 cross-chain · supply / PoR checks      │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
    ┌──────────────────────┐      ┌───────────────────────────┐
    │  IDataFeed (pricing) │      │ AggregatorV3Interface     │
    │  e.g. DataFeedContract│      │ (proof-of-reserve feed)  │
    └──────────────────────┘      └───────────────────────────┘
```

- **StableGold** is the main entry point. It reads gold spot prices from an `IDataFeed` implementation, optionally constrains minting against a Chainlink-compatible reserve feed, and exposes admin/owner configuration for fees, limits, and feature flags.
- **DataFeedContract** provides an admin-updated, epoch-based price feed compatible with the `IDataFeed` interface (Chainlink `latestRoundData` shape).
- **Libraries and interfaces** under `contracts/` supply ownership, math, strings, signature verification, and standard interfaces used by the token and feeds.

## Contract map

### Production contracts (`contracts/`)

| File | Role |
|------|------|
| [`StableGold.sol`](contracts/StableGold.sol) | Main gold-backed ERC20 token (includes inlined ERC20 base and OpenZeppelin-style utilities) |
| [`DataFeed.sol`](contracts/DataFeed.sol) | `DataFeedContract` — admin-managed gold price feed implementing `IDataFeed` |
| [`IDataFeed.sol`](contracts/IDataFeed.sol) | Price feed interface (`latestRoundData`, `getRoundData`, `decimals`) |
| [`AggregatorV3Interface.sol`](contracts/AggregatorV3Interface.sol) | Chainlink-compatible aggregator interface (used for proof-of-reserve) |
| [`AggregatorV3.sol`](contracts/AggregatorV3.sol) | Reserve aggregator helper contract |
| [`EIP3009.sol`](contracts/EIP3009.sol) | EIP-3009 transfer-with-authorization base (adapted from Circle; Apache-2.0) |
| [`IERC7802.sol`](contracts/IERC7802.sol) | Cross-chain ERC20 mint/burn interface |
| [`Ownable.sol`](contracts/Ownable.sol), [`Context.sol`](contracts/Context.sol) | Access control and execution context |
| [`Math.sol`](contracts/Math.sol), [`SignedMath.sol`](contracts/SignedMath.sol), [`Strings.sol`](contracts/Strings.sol) | Math and string utilities |
| [`MessageHashUtils.sol`](contracts/MessageHashUtils.sol), [`SignatureChecker.sol`](contracts/SignatureChecker.sol), [`ECRecover.sol`](contracts/ECRecover.sol), [`ECDSAUpgradeable.sol`](contracts/ECDSAUpgradeable.sol) | Signature and EIP-712 helpers |
| [`IERC1271.sol`](contracts/IERC1271.sol), [`IERC165.sol`](contracts/IERC165.sol) | Standard interfaces |

### Test and demo helpers (`contracts/test/`)

These files support local experimentation and are **not** intended as production deployments:

| Path | Role |
|------|------|
| [`contracts/test/DataFeed/`](contracts/test/DataFeed/) | Standalone DataFeed harness with duplicated utility contracts |
| [`contracts/test/DemoTokens/DemoToken18dec.sol`](contracts/test/DemoTokens/DemoToken18dec.sol) | 18-decimal demo ERC20 for integration testing |
| [`contracts/test/DemoTokens/DemoToken6dec.sol`](contracts/test/DemoTokens/DemoToken6dec.sol) | 6-decimal demo ERC20 for integration testing |


## Multisign ownership

Once the contract is deployed, ownership is transferred from the deployer to a [Safe{Wallet}](https://safe.global/) multisig—the original multisig wallet used for secure self-custody of owner-only actions. These include `pauseStatus`, `increaseSupply`, `reclaim`, `burnFreezedAssets`, and role management via `addAdmin`. Day-to-day operational roles (admin, authority, minter, custody) remain separate and are granted by the owner multisig.

## Controlling the token supply

StableGold supply is designed to stay aligned with verified physical gold inventory. Legal reserve obligations sit alongside on-chain caps and checks in [`StableGold.sol`](contracts/StableGold.sol).

- **Asset reserve backing:** Issuers are legally mandated to maintain a reserve of physical assets matching issued tokens.
- **Strict 1:1 reserve minting:** New tokens are minted only when physical gold bars are delivered, verified, and audited inside an approved secure vault. On-chain, minting is constrained by `maxSupply` and, when proof-of-reserve is enabled, by a reserve feed so circulating supply cannot exceed verified inventory.
- **Redemption burning:** When a token holder redeems digital tokens for physical gold, the corresponding tokens are permanently removed from circulation via `redeem` (burn or transfer to a dead address, depending on `burnRedeem` configuration).
- **Independent auditing:** Third-party auditors regularly verify vault physical inventory against on-chain `totalSupply()`.
- **Supply cap updates:** After audited inventory increases, the owner multisig calls `increaseSupply()` to raise `maxSupply`, allowing additional minting while preserving 1:1 backing with the physical asset.

The smart contract enforces configured caps and reserve checks; legal reserve obligations are maintained off-chain through issuer policy and audit processes.

## Safeguards and compliance controls

- **On-chain lockup:** If a regulator flags a specific wallet address, an authorized `admin` or `authority` role calls `freezeAddress`. While frozen, that address cannot transfer tokens, receive transfers, or redeem for physical gold—preserving asset status quo during investigations.
- **Supply re-balancing:** Upon legal execution, the owner multisig may `reclaim` frozen balances to a dedicated StableGen seizure wallet or call `burnFreezedAssets` to permanently destroy them (both require the address to be frozen first).
- **Emergency circuit breaker:** The owner sets `pause` via `pauseStatus(true)` to halt user-facing transfers, minting, primary purchase, redemption, on-chain buyback, and related signed-transfer flows network-wide.

Compliance operators are granted the **`authority`** role via `addAuthority` to perform actions such as freezing addresses, without full contract-owner privileges.

## Documentation

Refer to the link below for documentation on StableGen's framework and protocol architecture:

**[StableGen Documentation](https://)**

## License

The repository is released under the [MIT License](LICENSE), except where individual files state otherwise (for example, [`EIP3009.sol`](contracts/EIP3009.sol) carries Apache-2.0 attribution from Circle Internet Financial, adapted by Tether.to).

## Disclaimer

This software is provided **“as is”**, without warranty of any kind. It does **not** constitute financial, legal, or investment advice. Tokenized products on RWAs may be subject to regulatory requirements in your jurisdiction.

This repository does **not** constitute a crypto-asset white paper under Regulation (EU) 2023/1114 (MiCAR) and does **not** constitute an offer or solicitation. StableGen products may qualify as an asset-referenced tokens; offering, marketing, and provision of services may require authorization and publication of regulated disclosures elsewhere. Nothing here guarantees regulatory approval in any jurisdiction.

- Review all contracts and deployment parameters before mainnet use.
- Verify oracle feeds, reserve data, role assignments, and pause state independently.
- Do not commit private keys, RPC URLs with credentials, or other secrets to this repository.

For security issues, refer to project disclosure channels when published; until then, contact the maintainers through official StableGen channels.