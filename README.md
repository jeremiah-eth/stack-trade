# Stacks Prediction Market 🔮

A decentralized prediction market platform built on the Stacks blockchain, allowing users to trade on the outcome of future events using STX.

## 🚀 Deployed Contracts (Mainnet)

- **Prediction Market**: [`SP95KYNT2QWA2EXJS2WZT666ZVXDA4QV4AZZ2T5G.prediction-market`](https://explorer.hiro.so/txid/SP95KYNT2QWA2EXJS2WZT666ZVXDA4QV4AZZ2T5G.prediction-market?chain=mainnet)
- **Trade Token**: [`SP95KYNT2QWA2EXJS2WZT666ZVXDA4QV4AZZ2T5G.trade`](https://explorer.hiro.so/txid/SP95KYNT2QWA2EXJS2WZT666ZVXDA4QV4AZZ2T5G.trade?chain=mainnet)

## ✨ Features

- **Binary Markets**: Create markets with YES/NO outcomes.
- **Automated Market Maker (AMM)**: Uses a Constant Product Market Maker (CPMM) `x * y = k` algorithm for price discovery.
- **Liquidity Pools**: Each market has its own liquidity pool initialized by the creator.
- **Platform Fees**: 2% fee on every trade, collected in a protocol treasury.
- **Trustless Resolution**: Markets are resolved by the creator (future V2 will implement decentralized oracles).

## 🛠 Tech Stack

- **Smart Contracts**: Clarity 4 (Epoch 3.3)
- **Blockchain**: Stacks (Bitcoin L2)
- **Testing**: Vitest + Clarinet SDK

## ⚠️ Known Issues

### Clarity 4 `as-contract` Syntax
The current deployment uses **Clarity 4**. The standard `(as-contract ...)` function was removed/changed in this version.
- **Current Status**: A patch using `tx-sender` is temporarily in place to satisfy syntax checkers.
- **Effect**: This causes a "self-transfer" error `(err u2)` during internal contract operations like `create-market`.
- **Fix In Progress**: We are actively researching the correct signature for the replacement `as-contract?` function in Clarity 4 to restore full functionality.

## 📦 Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js (v18+)

### Installation
```bash
npm install
```

### Running Tests
```bash
npm test
```

## 📜 License
MIT
