import { StacksMocknet, StacksTestnet } from "@stacks/network";
import {
  broadcastTransaction,
  bufferCV,
  callReadOnlyFunction,
  compressPublicKey,
  contractPrincipalCV,
  createAssetInfo,
  createFungiblePostCondition,
  createStacksPrivateKey,
  createSTXPostCondition,
  cvToJSON,
  cvToString,
  FungibleConditionCode,
  getAddressFromPrivateKey,
  getAddressFromPublicKey,
  getPublicKey,
  listCV,
  makeContractCall,
  makeContractDeploy,
  makeContractFungiblePostCondition,
  makeContractSTXPostCondition,
  noneCV,
  PostConditionMode,
  standardPrincipalCV,
  stringAsciiCV,
  stringUtf8CV,
  TransactionVersion,
  trueCV,
  tupleCV,
  uintCV,
  someCV,
  OptionalCV
} from "@stacks/transactions";
// import { optionalCVOf } from "@stacks/transactions/dist/transactions/src/clarity/types/optionalCV";
import { principalCV } from "@stacks/transactions/dist/transactions/src/clarity/types/principalCV";
import * as bitcoin from 'bitcoinjs-lib'
import BN from "bn.js";
import {config} from 'dotenv'
import fs from 'fs'
import path from 'path'


config();


const contractName = "decent-delegate-v5"
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
  console.log(result);
}


console.log(bitcoin.address.fromBase58Check(bitcoinAddress as string).hash.toString('hex'))
const createStackingPool = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(86 * 15000000000),
      uintCV(100000000),
      uintCV(1),
      uintCV(7500000000),
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
  const tx = await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(86e12),
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
      uintCV(2e12),
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

const unwrap = async () => {
  const amount = 86e12
  const tx = await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(amount),
    ],
    functionName: 'unwrap-DDX',
    senderKey: process.env.KEY as string,
    network: network,
    postConditions: [
      createFungiblePostCondition(
        'ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7',
        FungibleConditionCode.Equal,
        new BN(amount),
        createAssetInfo('ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7', contractName, 'stacked-stx')
      ),
      createSTXPostCondition(
        `ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7.${contractName}`, 
        FungibleConditionCode.GreaterEqual,
        new BN(amount),
      ),
    ]
    // fee: new BN(100000000),
    // postConditionMode: PostConditionMode.Allow,
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

const redeemReward = async () => {
  const tx =await makeContractCall({
    contractAddress: "ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7",
    contractName,
    functionArgs: [
      uintCV(1),
    ],
    functionName: 'redeem-rewards',
    senderKey: process.env.KEY as string,
    network: network,
    // fee: new BN(100000000),
    postConditionMode: PostConditionMode.Allow,
  });
  const result = await broadcastTransaction(tx, network);
  const json = result;

  console.log(json);
}

const mintSeries = async () => {
  const tx = await makeContractCall({
    contractAddress: 'ST22HQ6YT0NAHB42F6X8PGZVA70S2XNB7KF03ZABX',
    contractName: 'immediate-jade-firefly',
    functionName: 'mint-series',
    functionArgs: [
      // (creator principal)
      // (creator-name (optional (tuple (namespace (buff 20)) (name (buff 48)))))
      // (existing-series-id (optional uint))
      // (series-name (string-utf8 80))
      // (series-uri (string-ascii 2048))
      // (series-mime-type (string-ascii 129))
      // (copies (list 50 uint)))
      standardPrincipalCV('ST21T5JFBQQPYQNQJRKYYJGQHW4A12G5ENBBA9WS7'),
      noneCV(),
      // noneCV(),
      someCV(uintCV(1)),
      stringUtf8CV("hozz"),
      stringAsciiCV("ha"),
      stringAsciiCV("stuff"),
      listCV(Array(12).fill(0).map((a, i) => uintCV(i)))
    ],
    
    senderKey: process.env.KEY as string,
    network: network
  })
  const result = await broadcastTransaction(tx, network);
  const json = result;

  console.log(json);

  // console.log(cvToString(stuff))
}



mintSeries();
// deployContract()
// createStackingPool();
// delegate()
// deposit()
// console.log(standardPrincipalCV("SP2F2NYNDDJTAXFB62PJX351DCM4ZNEVRYJSC92CT"));
// allowContractCaller();
// redeemReward()
// unwrap()