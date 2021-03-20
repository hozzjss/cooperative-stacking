import { StacksMocknet, StacksTestnet } from "@stacks/network";
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
  makeContractDeploy,
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
import fs from 'fs'
import path from 'path'
config();


const contractName = "decent-delegate-v1"
const testContractName = "elaborate-indigo-bird"

const network = new StacksMocknet();
// const network = new StacksTestnet();

const privateKey = createStacksPrivateKey(process.env.KEY as string);
const publicKey = getPublicKey(privateKey);
// const address = getAddressFromPrivateKey(process.env.KEY as string, TransactionVersion.Mainnet);
const pubKey = compressPublicKey(publicKey.data);

const stxAddress = getAddressFromPublicKey(pubKey.data);
const bitcoinAddress = bitcoin.payments.p2pkh({pubkey: pubKey.data}).address

// console.log(stxAddress, bitcoinAddress)


const deployContract = async () => {
  const tx = await makeContractDeploy({
    codeBody: fs.readFileSync(path.resolve('./contracts/decent-delegate.clar')).toString(),
    contractName,
    senderKey: process.env.KEY as string,
    network,
    fee: new BN(29000)
  });

  const result = await broadcastTransaction(tx, network);
  console.log({result});
}


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
      uintCV(86e12),
      tupleCV({
        hashbytes: bufferCV(bitcoin.address.fromBase58Check("msWypwkAVtyU7ombJuHVGXoRAtTYPVNUJx").hash),
        version: bufferCV(Buffer.alloc(1, 0))
      })
    ],
    functionName: 'create-decent-pool',
    senderKey: process.env.KEY as string,
    network: network,
    postConditionMode: PostConditionMode.Allow,
  });
  const result = await broadcastTransaction(tx, network);
  const json = result;

  console.log(json);
};

const delegate = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(20e12),
      trueCV()
    ],
    functionName: 'delegate',
    senderKey: process.env.KEY as string,
    network: network,
    postConditionMode: PostConditionMode.Allow,
    // fee: new BN(10000000)
  });
  const result = await broadcastTransaction(tx, network);
  const json = result;

  console.log(json);
};

const deposit = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(500e6),
    ],
    functionName: 'deposit-to-collateral',
    senderKey: process.env.KEY as string,
    network: network,
    // fee: new BN(100000000),
    postConditionMode: PostConditionMode.Allow,
  });
  const result = await broadcastTransaction(tx, network);
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
    network: network
  })
  const result = await broadcastTransaction(tx, network);

  console.log(result);
}


// deployContract()
// createStackingPool();
// delegate()
deposit()
// console.log(standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"));
// allowContractCaller();