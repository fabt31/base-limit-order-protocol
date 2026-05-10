# base-limit-order-protocol

> On-Chain Limit Order Protocol for Base L2

Place gasless limit orders on Base that execute automatically when price conditions are met. Built on top of Uniswap v3 and Aerodrome, with EIP-712 off-chain signing.

## Features
- 📋 Gasless limit order creation (off-chain signature)
- ⚡ Keeper-executed fills
- 🔄 Partial fills support
- ❌ On-chain cancellation
- 📅 Order expiration (TTL)
- 🪙 Support for any ERC20 pair on Base
- 🔒 Permit2 integration (no approval tx needed)

## Order Flow
```
User signs order off-chain (no gas)
     ↓
Keeper monitors for price condition
     ↓
Keeper calls fillOrder() when price met
     ↓
Tokens swap via Uniswap/Aerodrome
     ↓
Keeper gets 0.1% fill fee
```

## Usage
```typescript
import { createLimitOrder, signOrder } from "./src/orders";

const order = createLimitOrder({
  tokenIn: USDC, tokenOut: WETH,
  amountIn: "1000000000",  // 1000 USDC
  amountOutMin: "500000000000000000",  // 0.5 WETH min
  expiry: Math.floor(Date.now()/1000) + 86400,  // 24h
});

const signedOrder = await signOrder(order, signer, ORDER_CONTRACT);
// Submit to keeper network
```

## Contract Address (Base)
Deploy your own instance — see `script/Deploy.s.sol`

## License
MIT