import { Client, Provider, ProviderRegistry, Result } from "@blockstack/clarity";
import { standardPrincipalCV } from "@stacks/transactions";
import { assert } from "chai";

describe("decent delegate contract test suite", () => {
  let decentDelegateClient: Client;
  let provider: Provider;

  before(async () => {
    provider = await ProviderRegistry.createProvider();
    decentDelegateClient = new Client("SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB.decent-delegate", "decent-delegate", provider);
  });
  it("should have a valid syntax", async () => {
    await decentDelegateClient.checkContract();
  });

  describe("deploying an instance of the contract", () => {
    before(async () => {
      await decentDelegateClient.deployContract();
    });

    // it("Create pool", async () => {
    //   const tx = decentDelegateClient.createTransaction({
    //     method: {
    //       name: 'create-decent-pool',
    //       args: [
    //         "u15000000000",
    //         "u100000000",
    //         "u1",
    //         "u1",
    //         "u1000",
    //         "u1000000000000",
    //         "{hash: 0x0000000000000000000000000000000000000000, version: 0x00}",
    //       ]
    //     },
    //   })
    //   // query.sign('421a4472c07e13886eaa9229573140ad5e889f3dd7090ab4ac919e5d84b9dce8')
    //   tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
    //   const receipt = await decentDelegateClient.submitTransaction(tx);
    //   const result = Result.unwrap(receipt);
    //   console.log(result);
    // })
    // it("should return 'decent delegate'", async () => {
    //   const query = decentDelegateClient.createQuery({ method: { name: "say-hi", args: [] } });
    //   const receipt = await decentDelegateClient.submitQuery(query);
    //   const result = Result.unwrapString(receipt, "utf8");
    //   assert.equal(result, "decent delegate");
    // });

    // it("should echo number", async () => {
    //   const query = decentDelegateClient.createQuery({
    //     method: { name: "echo-number", args: ["123"] }
    //   });
    //   const receipt = await decentDelegateClient.submitQuery(query);
    //   const result = Result.unwrapInt(receipt)
    //   assert.equal(result, 123);
    // });
  });

  after(async () => {
    await provider.close();
  });
});
