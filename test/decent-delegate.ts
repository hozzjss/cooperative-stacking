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
    it("should show something", async () => {
      const query = decentDelegateClient.createTransaction({
        method: {
          name: 'util-delete-me',
          args: ["0x03ae50baea8b5033c91ea0ff0d7b4182fb8950e286553f70212eceeb9fa88afef8"]
        },
      })
      // query.sign('421a4472c07e13886eaa9229573140ad5e889f3dd7090ab4ac919e5d84b9dce8')
      query.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
      const receipt = await decentDelegateClient.submitTransaction(query);
      const result = Result.unwrap(receipt);
      console.log(result);
    })
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
