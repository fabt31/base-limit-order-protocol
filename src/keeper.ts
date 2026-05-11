import { ethers } from "ethers";
interface SignedOrder { order: any; sig: string; }
export class KeeperBot {
  private provider: ethers.JsonRpcProvider;
  private wallet: ethers.Wallet;
  private protocolAddress: string;
  constructor(rpc: string, privateKey: string, protocol: string) {
    this.provider = new ethers.JsonRpcProvider(rpc);
    this.wallet = new ethers.Wallet(privateKey, this.provider);
    this.protocolAddress = protocol;
  }
  async checkAndFill(signedOrder: SignedOrder): Promise<boolean> {
    const { order } = signedOrder;
    if (Date.now() / 1000 > order.expiry) { console.log("Order expired"); return false; }
    console.log(`Checking order: ${order.tokenIn} → ${order.tokenOut}`);
    return true;
  }
}
