# Hoodi testnet

Testnet deployments on Ethereum Hoodi (chain ID `560048`). **Not for production.**

Explorer: [hoodi.etherscan.io](https://hoodi.etherscan.io/)

| Field | Value |
|-------|--------|
| Compiler | solc `0.8.30+commit.73712a01` |
| Optimizer | `200` runs |
| Deployer / owner | [`0xD450b96143d8E322b9C783b1eE3a2e43B5BbB8dC`](https://hoodi.etherscan.io/address/0xD450b96143d8E322b9C783b1eE3a2e43B5BbB8dC) |

Ownership remains this deployer EOA for testing. It will **not** be transferred to a Safe on Hoodi.

See the address index: [DEPLOYMENTS.md](../DEPLOYMENTS.md).

## StableGold (STBG)

| Field | Value |
|-------|--------|
| Status | Testnet (unpaused; public sale enabled) |
| Address | [`0x62d515Bd4E9119C7300EA097E353FE4C23AF528d`](https://hoodi.etherscan.io/address/0x62d515Bd4E9119C7300EA097E353FE4C23AF528d) |
| Name / symbol | StableGold / STBG |
| Decimals | 18 |
| Deploy tx | [`0x978d1375…5d6c`](https://hoodi.etherscan.io/tx/0x978d13753c35bf55b0f2e8e9a472ff8bd40bfaac10001e438ec6b0fbe4595d6c) |
| Block | `3451703` |
| Sourcify | [Exact match](https://repo.sourcify.dev/560048/0x62d515Bd4E9119C7300EA097E353FE4C23AF528d) (verified 2026-08-19) |
| Owner / admin | Deployer EOA (unchanged) |
| `premium` | `300` bps (3%) |
| `onchainBuyBackFee` | `300` bps (3%) |

### Constructor

| Parameter | Value |
|-----------|--------|
| `_name` | `StableGold` |
| `_symbol` | `STBG` |
| `_premintSupply` | `10000000000000000000` (10 STBG) |
| `_initialMaxSupply` | `1000000000000000000000` (1,000 STBG) |
| `_priceFeed` | [`0xeEbbF36081F2e9B1c500e34805236c008b0192A0`](https://hoodi.etherscan.io/address/0xeebbf36081f2e9b1c500e34805236c008b0192a0) |
| `_dataFeedHeartbeat` | `2592000` (30 days) |

Constructor defaults (until changed): `pause = true`, `burnRedeem = true`, `buyBackAddress = address(this)`, deployer is owner and admin.

### Post-deploy configuration

| Step | Function | Result |
|------|----------|--------|
| Unpause | `pauseStatus(false)` | Contract unpaused |
| Settlement assets | `addAcceptedStables` | Demo 18-dec and 6-dec tokens accepted |
| Purchase premium | `updatePremium(300)` | 300 bps (3%) on top of spot for `buy` |
| Public sale | `updateSaleStatus(true)` | Open `buy` |
| Buyback fee | `updateOnChainBuyBackFee(300)` | 300 bps (3%) deducted from spot for `onchainBuyBack` |
| Buyback enabled | `updateOnChainBuyBackStatus(true)` | On-chain buyback active |
| Buyback liquidity | `approveTokenContract` | Stablecoin allowance for buybacks (e.g. 10,000 units) |

### Smoke tests

| Flow | Tx |
|------|----|
| Buy ~1 STBG with 18-dec demo token | [`0x71d0ad0b…2c0a`](https://hoodi.etherscan.io/tx/0x71d0ad0bb3c1279f5b81be07ff4572639094119da505507a735d0d2660c62c0a) |
| Buy ~1 STBG with 6-dec demo token | [`0xa029860c…7932`](https://hoodi.etherscan.io/tx/0xa029860c85c306bd1713bdb53e016e8378bd39c9370eca304ae4eb0f8ab37932) |
| Sell 0.5 STBG for 18-dec demo token | [`0x81edd50d…fb60`](https://hoodi.etherscan.io/tx/0x81edd50d83c86780e722192f9f649e1e9b7e4058538bf98f70d9923a95d7fb60) |
| Sell 0.5 STBG for 6-dec demo token | [`0xd5bca575…2b51`](https://hoodi.etherscan.io/tx/0xd5bca5755b2d0beb7c370c2a38d39f959b2e09f6a7fbc0cbcb884992189e2b51) |

Callers must `approve` the demo token (for `buy`) or STBG (for `onchainBuyBack`) before those calls.

### Related contracts

| Contract | Address | Notes |
|----------|---------|--------|
| Price feed (`DataFeedContract`) | [`0xeEbbF36081F2e9B1c500e34805236c008b0192A0`](https://hoodi.etherscan.io/address/0xeebbf36081f2e9b1c500e34805236c008b0192a0) | Wired as `_priceFeed` |
| Prior DataFeed (not used by STBG) | [`0x67979D862FA17C2E54897Fab431D54400806aF49`](https://repo.sourcify.dev/560048/0x67979D862FA17C2E54897Fab431D54400806aF49) | Earlier feed; superseded |
| Proof-of-reserve | unset | `proofOfReserveEnabled` false at deploy |
| Token bridge | unset | IERC7802 not configured |

## Test settlement tokens (`contracts/test/DemoTokens/`)

Not production. Used only to exercise 6- and 18-decimal `buy` / `onchainBuyBack` on Hoodi.

| Token | Address | Minted | Deploy tx |
|-------|---------|--------|-----------|
| Demo 18-dec | [`0xbaB71baFeDB7c21ED7b3AC18633C80326187BE7a`](https://hoodi.etherscan.io/address/0xbab71bafedb7c21ed7b3ac18633c80326187be7a) | `1_000_000e18` | [`0x9adf88cc…ef51`](https://hoodi.etherscan.io/tx/0x9adf88cc2808b5247f24e9861afe0daae2d223c31d5a3868de46bd9042fcef51) |
| Demo 6-dec | [`0x8FEd590CF086acB199715fe630551b51865016c0`](https://hoodi.etherscan.io/address/0x8fed590cf086acb199715fe630551b51865016c0) | `10_000e6` | [`0xfc0f37b7…3b67`](https://hoodi.etherscan.io/tx/0xfc0f37b71f35e1e9b7c59f4fbaa0cdc593d5b16e655e76e4844ac1c2dcad3b67) |

## Notes

- Hoodi is for integration testing. Production ownership is expected to be a Safe; that transfer is **not** done on this testnet.
- EIP-712 domain in the contract is hardcoded as name `Stablegold`, version `1` (independent of the ERC20 name).
