# Deployments

Canonical on-chain addresses for contracts in this repository.

An entry applies to the named network, contract, and Git revision. Test helpers under `contracts/test/` are not production. Testnet addresses are **not** for production use.

Verify addresses on a block explorer and match bytecode to the listed verification before integrating.

## Mainnet

| Network | Contract | Address | Status | Details |
|---------|----------|---------|--------|---------|
| Ethereum mainnet (`1`) | StableGold (STBG) | — | Not deployed | [ethereum-mainnet.md](deployments/ethereum-mainnet.md) |

## Testnet

| Network | Contract | Address | Status | Details |
|---------|----------|---------|--------|---------|
| Hoodi testnet (`560048`) | StableGold (STBG) | [`0x62d515Bd4E9119C7300EA097E353FE4C23AF528d`](https://hoodi.etherscan.io/address/0x62d515Bd4E9119C7300EA097E353FE4C23AF528d) | Testnet | [hoodi-testnet.md](deployments/hoodi-testnet.md) |
| Hoodi testnet (`560048`) | DataFeed | [`0xeEbbF36081F2e9B1c500e34805236c008b0192A0`](https://hoodi.etherscan.io/address/0xeebbf36081f2e9b1c500e34805236c008b0192a0) | Testnet (wired to STBG) | [hoodi-testnet.md](deployments/hoodi-testnet.md) |
| Hoodi testnet (`560048`) | Demo token (18-dec) | [`0xbaB71baFeDB7c21ED7b3AC18633C80326187BE7a`](https://hoodi.etherscan.io/address/0xbab71bafedb7c21ed7b3ac18633c80326187be7a) | Test helper | [hoodi-testnet.md](deployments/hoodi-testnet.md) |
| Hoodi testnet (`560048`) | Demo token (6-dec) | [`0x8FEd590CF086acB199715fe630551b51865016c0`](https://hoodi.etherscan.io/address/0x8fed590cf086acb199715fe630551b51865016c0) | Test helper | [hoodi-testnet.md](deployments/hoodi-testnet.md) |
