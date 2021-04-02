import { Client, JsonRpcProvider, NativeClarityBinProvider, Provider, ProviderRegistry, Result, unwrapResult } from "@blockstack/clarity";
import { getDefaultBinaryFilePath } from "@blockstack/clarity-native-bin";
import { createStacksPrivateKey, getAddressFromPrivateKey, makeRandomPrivKey, pubKeyfromPrivKey, standardPrincipalCV } from "@stacks/transactions";
import { assert, expect } from "chai";
import {
  getTempFilePath
} from "@blockstack/clarity/lib/utils/fsUtil";

import {DDXClient} from './ddx-client'

const multipleContributors = Array(4).fill({key: '', address: ''}).map(() => {
  const key = makeRandomPrivKey();
  const publicKey = pubKeyfromPrivKey(key.data);
  const address = getAddressFromPrivateKey(key.data);
  return {
    key,
    address
  }
})

const multipleAllocations = multipleContributors.map(contrib => ({
  principal: contrib.address,
  amount: 1e18
}))

describe("decent delegate contract test suite", () => {
  let decentDelegateClient: DDXClient;
  let poxClient: Client;
  let ftTraitClient: Client;
  let playgroundClient: Client;
  let provider: NativeClarityBinProvider;

  before(async () => {
    provider = await NativeClarityBinProvider.create([
      {
        amount: 1e18,
        principal: "SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB"
      },
      ...multipleAllocations,
    ], getTempFilePath(), getDefaultBinaryFilePath());

    decentDelegateClient = new DDXClient(provider);
    poxClient = new Client("ST000000000000000000002AMW42H.pox", "pox", provider);
    playgroundClient = new Client("SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB.playground", 'playground', provider);
    ftTraitClient = new Client("SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-10-ft-standard", "sip-10-ft-standard", provider);
  });

  describe("Best case scenarios", () => {
    const getBalance = async (address: string) => {
      const query = playgroundClient.createQuery({
        method: {
          args: [`'${address}`],
          name: "get-my-balance"
        },
      })
      const receipt = await playgroundClient.submitQuery(query)
      return Result.unwrapUInt(receipt);
    }
    before(async () => {
      await poxClient.checkContract();
      await poxClient.deployContract();
      await ftTraitClient.checkContract();
      await ftTraitClient.deployContract();
      await decentDelegateClient.checkContract();
      await decentDelegateClient.deployContract();
      await playgroundClient.checkContract();
      await playgroundClient.deployContract();
    });
    
    it('should create a pool', async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'create-decent-pool',
          args: [
            "u" + 15000000000 * 90,
            "u100000000",
            "u1",
            "u" + 15000000000 * 45,
            "u" + 90e12,
            "{hashbytes: 0x83a2c9ebbdedebd6f2c4fde942f1e1141140aeaa, version: 0x00}",
          ]
        },
      })
      // query.sign('421a4472c07e13886eaa9229573140ad5e889f3dd7090ab4ac919e5d84b9dce8')
      tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
      const receipt = await decentDelegateClient.submitTransaction(tx);
      const result = Result.unwrap(receipt);
      expect(receipt.success).eq(true)
    })

    it('should delegate by taking stx from sender', async () => {
      for (let contrib of multipleContributors) {
        const tx = decentDelegateClient.createTransaction({
          method: {
            name: 'delegate',
            args: [
              "u" + 90e11,
              "true",
            ]
          },
        })
        // query.sign('421a4472c07e13886eaa9229573140ad5e889f3dd7090ab4ac919e5d84b9dce8')
        tx.sign(contrib.address)
        await decentDelegateClient.submitTransaction(tx);
        const receipt = await decentDelegateClient.submitTransaction(tx);
        const result = Result.extract(receipt);
        expect(result.success).equal(true)
      }
    })

    it("should reject stacking requests lower than the minimum", async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'delegate',
          args: [
            "u100",
            "false"
          ]
        }
      });
      tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')

      const result = await decentDelegateClient.submitTransaction(tx);
      
      expect(Result.extract(result).success).equal(false, "Minimum required");
    })

    it("should stack once it reaches goal", async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'delegate',
          args: [
            "u" + 100e12,
            "false"
          ]
        }
      });
      tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')

      const result = await decentDelegateClient.submitTransaction(tx);

      expect(Result.extract(result).success).equal(true, "Stacked");
    })

    it('should be able to withdraw rewards prematurely', async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'redeem-rewards',
          args: ['u1']
        },
      })
      tx.sign(multipleAllocations[0].principal)
      
      const result =  await decentDelegateClient.submitTransaction(tx)
      console.log(result)
      expect(result.success).to.eq(true)
    })

    it('should allow stacker to deposit after stacking starts', async () => {
      await decentDelegateClient.mineBlocks(50)
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'deposit-to-collateral',
          args: ['u' + 15000000000 * 45]
        },
      })
      tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
      
      const result =  await decentDelegateClient.submitTransaction(tx)
      expect(result.success).to.eq(true)
    })



    it('should get the current reward cycle', async () => {
      // await decentDelegateClient.mineBlocks(70)
      const tx = decentDelegateClient.createQuery({
        method: {
          name: 'get-current-cycle-id',
          args: []
        }
      });
      // tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
      const result = await decentDelegateClient.submitQuery(tx);

      expect(Result.unwrap(result)).to.eq('u1')
    })

    it('should unwrap ddx for stx', async () => {
      await decentDelegateClient.mineBlocks(200)
      const address = multipleAllocations[0].principal;
      const balanceBefore = await getBalance(address);
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'unwrap-DDX',
          args: ['u7500000000']
        },
      })
      tx.sign(address)
      
      const result =  await decentDelegateClient.submitTransaction(tx)
      const balanceAfter = await getBalance(address);
      assert.equal(balanceBefore + 7500000000, balanceAfter)
      // expect(result.success).to.eq(true)
    })

    it('should be able to withdraw rewards a second time if more rewards are there', async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'redeem-rewards',
          args: ['u1']
        },
      })
      tx.sign(multipleAllocations[0].principal)
      
      const result =  await decentDelegateClient.submitTransaction(tx)
      console.log(result)
      expect(result.success).to.eq(true)
    })


    it('should be able to withdraw full rewards at the end of the cycle', async () => {
      const tx = decentDelegateClient.createTransaction({
        method: {
          name: 'redeem-rewards',
          args: ['u1']
        },
      })
      tx.sign(multipleAllocations[1].principal)
      
      const result =  await decentDelegateClient.submitTransaction(tx)
      expect(result.success).to.eq(true)
    })


    
    // it("it should stack", async () => {
    //   const tx = poxClient.createTransaction({
    //     method: {
    //       name: 'stack-stx',
    //       args: [
    //         "u100000000000",
    //         "{hashbytes: 0x83a2c9ebbdedebd6f2c4fde942f1e1141140aeaa, version: 0x00}",
    //         "u1940641",
    //         "u1"
    //       ]
    //     },
    //   })
    //   // query.sign('421a4472c07e13886eaa9229573140ad5e889f3dd7090ab4ac919e5d84b9dce8')
    //   tx.sign('SP3GWX3NE58KXHESRYE4DYQ1S31PQJTCRXB3PE9SB')
    //   const receipt = await poxClient.submitTransaction(tx);
    //   const result = Result.unwrap(receipt);
    // })

    // it('should ')
  });

  after(async () => {
    await provider.close();
  });
});
