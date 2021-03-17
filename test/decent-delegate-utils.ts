import { StacksTestnet } from "@stacks/network";
import {
  broadcastTransaction,
  bufferCV,
  callReadOnlyFunction,
  compressPublicKey,
  contractPrincipalCV,
  createStacksPrivateKey,
  createSTXPostCondition,
  cvToJSON,
  FungibleConditionCode,
  getAddressFromPrivateKey,
  getAddressFromPublicKey,
  getPublicKey,
  makeContractCall,
  noneCV,
  PostConditionMode,
  standardPrincipalCV,
  TransactionVersion,
  trueCV,
  tupleCV,
  uintCV,
} from "@stacks/transactions";
import * as bitcoin from 'bitcoinjs-lib'
import BN from "bn.js";
import {config} from 'dotenv'
config();


const contractName = "cool-scarlet-swordfish"
const testContractName = "elaborate-indigo-bird"

const privateKey = createStacksPrivateKey(process.env.KEY as string);
const publicKey = getPublicKey(privateKey);
// const address = getAddressFromPrivateKey(process.env.KEY as string, TransactionVersion.Mainnet);
const pubKey = compressPublicKey(publicKey.data);

const stxAddress = getAddressFromPublicKey(pubKey.data);
const bitcoinAddress = bitcoin.payments.p2pkh({pubkey: pubKey.data}).address

// console.log(stxAddress, bitcoinAddress)



console.log(bitcoin.address.fromBase58Check(bitcoinAddress as string).hash.toString('hex'))
const createStackingPool = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(15000000000),
      uintCV(100000000),
      uintCV(1),
      uintCV(7500000000),
      uintCV(1000),
      uintCV(90e12),
      tupleCV({
        hashbytes: bufferCV(bitcoin.address.fromBase58Check("msWypwkAVtyU7ombJuHVGXoRAtTYPVNUJx").hash),
        version: bufferCV(Buffer.alloc(1, 0))
      })
      // standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"),
    ],
    functionName: 'create-decent-pool',
    // senderAddress: "ST000000000000000000002AMW42H",
    senderKey: process.env.KEY as string,
    network: new StacksTestnet(),
    // postConditions: [
    //   createSTXPostCondition(
    //     'ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7',
    //     FungibleConditionCode.GreaterEqual,
    //     new BN(1000000))
    // ]
    postConditionMode: PostConditionMode.Allow,
  });
  const result = await broadcastTransaction(tx, new StacksTestnet());
  const json = result;

  console.log(json);
};

const delegate = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(15e12),
      trueCV()
      // standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"),
    ],
    functionName: 'delegate',
    // senderAddress: "ST000000000000000000002AMW42H",
    senderKey: process.env.KEY as string,
    network: new StacksTestnet(),
    // postConditions: [
    //   createSTXPostCondition(
    //     'ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7',
    //     FungibleConditionCode.GreaterEqual,
    //     new BN(1000000))
    // ]
    postConditionMode: PostConditionMode.Allow,
    nonce: new BN(91)
  });
  const result = await broadcastTransaction(tx, new StacksTestnet());
  const json = result;

  console.log(json);
};

const allowContractCaller = async () => {
  const tx = await makeContractCall({
    contractAddress: 'ST000000000000000000002AMW42H',
    contractName: 'pox',
    functionName: 'allow-contract-caller',
    functionArgs: [
      contractPrincipalCV("ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7", contractName),
      noneCV()
    ],
    senderKey: process.env.KEY as string,
    network: new StacksTestnet()
  })
  const result = await broadcastTransaction(tx, new StacksTestnet());

  console.log(result);
}
// allowContractCaller();
// delegate()
// createStackingPool();
// console.log(standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"));
