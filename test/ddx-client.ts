import { Client, NativeClarityBinProvider } from "@blockstack/clarity";

export class DDXClient extends Client {

  constructor(provider: NativeClarityBinProvider) {
    super("SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB.decent-delegate", "../contracts/decent-delegate", provider)
  }
  async mineBlocks(blocks: number) {
    for (let i = 0; i < blocks; i ++) {
      const query = this.createQuery({
        atChaintip: false,
        method: {
          "args": [],
          name: "get-decimals"
        }
      })
      const result = await this.submitQuery(query);
    }
  }

  async createStackingPool() {

  }
}