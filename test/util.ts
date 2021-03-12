import {
  callReadOnlyFunction,
  cvToJSON,
  standardPrincipalCV,
} from "@stacks/transactions";
import {address} from 'bitcoinjs-lib'

console.log(address.fromBase58Check("msWypwkAVtyU7ombJuHVGXoRAtTYPVNUJx").hash.toString('hex'))
const run = async () => {
  const result =await callReadOnlyFunction({
    contractAddress: "SP000000000000000000002Q6VF78",
    contractName: "pox",
    functionArgs: [
      standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"),
    ],
    functionName: 'get-stacker-info',
    senderAddress: "SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"
  });
  const json = cvToJSON(result);

  console.log(json);
};
run();
// console.log(standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"));
