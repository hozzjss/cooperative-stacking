import { StacksTestnet } from "@stacks/network";
import {
  callReadOnlyFunction,
  cvToJSON,
  standardPrincipalCV,
} from "@stacks/transactions";
import {address} from 'bitcoinjs-lib'

console.log(address.fromBase58Check("msWypwkAVtyU7ombJuHVGXoRAtTYPVNUJx").hash.toString('hex'))
const run = async () => {
  const result =await callReadOnlyFunction({
    contractAddress: "ST000000000000000000002AMW42H",
    contractName: "pox",
    functionArgs: [
      // standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"),
    ],
    functionName: 'get-pox-info',
    senderAddress: "ST000000000000000000002AMW42H",
    network: new StacksTestnet()
  });
  const json = cvToJSON(result);

  console.log(json);
};
run();
// console.log(standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"));
