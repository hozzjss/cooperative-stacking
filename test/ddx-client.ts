import { Client, NativeClarityBinProvider } from "@blockstack/clarity";
import * as bitcoin from "bitcoinjs-lib";

export class DDXClient extends Client {
  constructor(provider: NativeClarityBinProvider) {
    super(
      "SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB.decent-delegate",
      "../contracts/decent-delegate",
      provider
    );
  }
  async mineBlocks(blocks: number) {
    for (let i = 0; i < blocks; i++) {
      const query = this.createQuery({
        atChaintip: false,
        method: {
          args: [],
          name: "get-decimals",
        },
      });
      await this.submitQuery(query);
    }
  }

  async createStackingPool(
    totalRewards: number,
    minimumStake: number,
    cycles: number,
    collateral: number,
    collateralLockPeriod: number,
    totalRequiredStake: number,
    poxAddress: string,
    poxAddressVersion: 0 | 1 | 2 | 3
  ) {
    const hashBytes = bitcoin.address.fromBase58Check(poxAddress)
    const tx = this.createTransaction({
      method: {
        name: "create-decent-pool",
        args: [
          `u${totalRewards}`,
          `u${minimumStake}`,
          `u${cycles}`,
          `u${collateral}`,
          `u${collateralLockPeriod}`,
          `u${totalRequiredStake}`,
          `{hashbytes: ${hashBytes}, version: 0x0${poxAddressVersion}}`,
        ],
      },
    });
    tx.sign("SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB");
    return this.submitTransaction(tx);
  }
}
