# CHANGELOG

All notable changes to the StableGen smart contract codebase will be documented in this file.

The purpose of this changelog is to provide a concise overview of material updates, fixes, security improvements, and release milestones. Detailed implementation history remains available through the Git commit history and pull requests.

## [v2.17.4] - 2026-08-19

### OpenZeppelin Security Audit Release

This release represents the StableGold (STBG) codebase following completion of the OpenZeppelin security audit and remediation process.

OpenZeppelin audited the StableGold smart contracts. No Critical-severity issues were identified. The single High-severity finding and all three Medium-severity findings were resolved during the engagement. Additional Low-severity and informational findings were also addressed where appropriate. The final audit report confirms that the implemented remediation fixes were merged into the codebase at commit `bcd20cb`.

### Security and Functional Improvements

- Strengthened freeze controls across transfers, burns, minting, and cross-chain operations.
- Added freeze enforcement to `burn` and `burnFrom`.
- Improved cross-chain compliance controls for `crosschainMint` and `crosschainBurn`.
- Migrated ERC-20 token interactions to `SafeERC20` for improved compatibility with tokens such as USDT.
- Added validation to prevent `premintSupply` from exceeding `maxSupply`.
- Added non-zero oracle heartbeat validation.
- Improved handling of 6-decimal and 18-decimal settlement tokens.
- Added minimum-output protection for on-chain buyback transactions.
- Improved EIP-3009 helper encoding behavior.
- Standardized use of `_msgSender`.
- Added a security contact declaration.
- Added NatSpec documentation and code comments across the contract interface.
- Added explicit error handling for unsupported redemption options.
- Improved arithmetic precision in token purchase calculations.
- Added validation preventing Proof-of-Reserve from being enabled with a zero feed address.
- Separated previously flattened contract declarations into individual source files.

### Operational and Design Decisions

Several findings were acknowledged as intentional design or operational decisions and remain documented in the OpenZeppelin audit, including:

- The `admin` role acting as an operational superset of `authority`, `custody`, and `minter`.
- Selective event emission for privileged configuration changes.
- Restricting accepted settlement assets to approved, well-behaved stablecoins.
- Lifetime semantics for the on-chain buyback limit.
- Single-step ownership transfer, with production ownership intended to be assigned to a multisig.
- Operational handling of buyback liquidity and fee accounting.
- Fixed EIP-712 domain configuration.
- Separate interfaces for price and reserve feeds.

### Audit Reference

- **Auditor:** OpenZeppelin
- **Final Audit Report:** 19 August 2026
- **Initial Audited Commit:** `22283f5cf75d75a76f38731e147782aaef388e18`
- **Final Remediation Merge Commit:** `bcd20cb`
- **Release Tag:** `v2.17.4`
- **Release Status:** OpenZeppelin-audited baseline

Further releases will be documented above this entry in reverse chronological order.