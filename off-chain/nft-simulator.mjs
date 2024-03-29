import {FlowService, settlement, sendTransaction, execScripts} from './scaffold-flow/flowoffchain.mjs'
import fcl, { send } from '@onflow/fcl';
import * as types from "@onflow/types";
import { SHA3 } from 'sha3';
import keccak256 from 'keccak256';
import oc from './scaffold-flow/omnichainCrypto.js';
import {opType, OmniverseNFTPayload, OmniverseNFTProtocol} from './erc6358types.js';

// import fs from 'fs';
// import path from 'path';

import {program} from 'commander';

const sha3_256FromString = (msg) => {
    const sha = new SHA3(256);
    sha.update(Buffer.from(msg, 'hex'));
    return sha.digest();
};

const fs_owner = new FlowService('0xf8d6e0586b0a20c7', 
                                    '69e7e51ead557351ade7a575e947c4d4bd19dd8a6cdf00c51f9c7f6f721b72dc',
                                    0,
                                    sha3_256FromString,
                                    'secp256k1');

const fsAlice = new FlowService('0x01cf0e2f2f715450', 
                                    'c9193930b34dd498378e36c35118a627d9eb500f6fd69b16d8e59db7cc8f5bb3',
                                    0,
                                    sha3_256FromString,
                                    'secp256k1');

const fsBob = new FlowService('0x179b6b1cb6755e31', 
                                    'd95472318e773b2046b078ae252c42082752c7b7876ce2770a2d3e00b02bbed5',
                                    0,
                                    sha3_256FromString,
                                    'secp256k1');

const fsCarl = new FlowService('0xf3fcd2c1a78f5eee', 
                                    'f559fa403545e328ea024ef27e030a478634ae04212519e8bb5293add4b6dda4',
                                    0,
                                    sha3_256FromString,
                                    'secp256k1');

const fs_map = {
    "owner": fs_owner,
    "Alice": fsAlice,
    "Bob": fsBob,
    "Carl": fsCarl
}

async function testSignature(pk, txRawData, signature) {
    const flc_args = [
        fcl.arg(pk, types.String),
        fcl.arg(txRawData, types.String),
        fcl.arg(signature, types.String)
    ];

    console.log(await execScripts({
        flowService: fs_owner,
        script_path: "../test/testSignature.cdc",
        args: flc_args
    }));
}

async function setMembers(members) {
    // console.log(members);
    // let fcl_arg = fcl.arg([{key: 1, value: "one"}, {key: 2, value: "two"}], types.Dictionary({key: types.UInt32, value: types.String}));
    let fcl_arg = fcl.arg(JSON.parse(members), types.Dictionary({key: types.UInt32, value: types.String}));

    let response = await sendTransaction({flowService: fs_owner, tx_path: "../transactions/setMembers.cdc", args: [fcl_arg]});

    const rst = await settlement(response);
    console.log(rst.data);
}

async function checkMembers() {
    let rstData = await execScripts({flowService: fs_owner, script_path: "../scripts/getMembers.cdc", args: []});

    console.log(rstData);
}

async function setLockPeriod(period) {
    let fcl_arg = fcl.arg(period, types.UFix64);

    const rst = await settlement(await sendTransaction({flowService: fs_owner, tx_path: "../transactions/setLockPeriod.cdc", args: [fcl_arg]}));
    console.log(rst.data);
}

async function checkLockPeriod() {
    console.log(await execScripts({flowService: fs_owner, script_path: "../scripts/getLockPeriod.cdc", args: []}));
}

async function checkSimuAccounts() {
    const keys = Object.keys(fs_map);
    for (var i in keys) {
        const tempOC = new oc.OmnichainCrypto(keccak256, 'secp256k1', fs_map[keys[i]].signerPrivateKeyHex);
        console.log("Account: " + keys[i]);
        console.log("Public Key: "+ tempOC.getPublic());
        console.log("**********************************");
    }
}

async function sendEmptyTx() {
    await sendTransaction({flowService: fs_owner, 
        tx_path: "../transactions/empty.cdc", 
        args: []});
}

async function sendOmniverseTransaction(from, to, tokenId, op_type) {
    const opOc = new oc.OmnichainCrypto(keccak256, 'secp256k1', fs_map[from].signerPrivateKeyHex);

    const nftMeta = await execScripts({
        flowService: fs_map[from], 
        script_path: "../scripts/getNFTTxMeta.cdc", 
        args: [
            fcl.arg(Array.from(Buffer.from(opOc.getPublic().substring(2), 'hex')).map((item) => {return String(item)}), types.Array(types.UInt8))
        ]
    });
    console.log(nftMeta);

    const oNFTPayload = new OmniverseNFTPayload(op_type, to, tokenId, await fcl.config.get('Profile'));
    // console.log(oNFTPayload.get_fcl_arg().value.fields);
    const oNFTTxData = new OmniverseNFTProtocol(nftMeta.nonce, nftMeta.flowChainId, nftMeta.contractName, Buffer.from(opOc.getPublic().substring(2), "hex"), oNFTPayload, await fcl.config.get('Profile'));
    // console.log(oNFTTxData.get_fcl_arg().value.fields);

    const txRawData = await execScripts({
        flowService: fs_map[from], 
        script_path: "../scripts/getRawTxData.cdc", 
        args: [
            oNFTTxData.get_fcl_arg()
        ]
    });

    oNFTTxData.signature = new Uint8Array(opOc.sign2buffer(Buffer.from(txRawData, "hex")));

    let response = await sendTransaction({flowService: fs_map[from], 
        tx_path: "../transactions/sendNFT.cdc", 
        args: [oNFTTxData.get_fcl_arg()]});

    let rst = await settlement(response);
    if (true == rst.status) {
        console.log(rst.data.events[0].data);
    }
}

async function nftTransfer(from, to, tokenId) {
    const toOc = new oc.OmnichainCrypto(keccak256, 'secp256k1', fs_map[to].signerPrivateKeyHex);
    await sendOmniverseTransaction(from, Buffer.from(toOc.getPublic().substring(2), "hex"), tokenId, opType.o_transfer);
}

async function nftBurn(from, tokenId) {
    await sendOmniverseTransaction(from, new Uint8Array(), tokenId, opType.o_burn);
}

async function nftMint() {
    const ownerOC = new oc.OmnichainCrypto(keccak256, 'secp256k1', fs_owner.signerPrivateKeyHex);

    const nftMeta = await execScripts({
        flowService: fs_owner, 
        script_path: "../scripts/getNFTTxMeta.cdc", 
        args: [
            fcl.arg(Array.from(Buffer.from(ownerOC.getPublic().substring(2), 'hex')).map((item) => {return String(item)}), types.Array(types.UInt8))
        ]
    });
    console.log(nftMeta);

    const oNFTPayload = new OmniverseNFTPayload(opType.o_mint, Buffer.from(ownerOC.getPublic().substring(2), "hex"), nftMeta.nextNFTId, await fcl.config.get('Profile'));
    // console.log(oNFTPayload.get_fcl_arg().value.fields);
    const oNFTTxData = new OmniverseNFTProtocol(nftMeta.nonce, nftMeta.flowChainId, nftMeta.contractName, Buffer.from(ownerOC.getPublic().substring(2), "hex"), oNFTPayload, await fcl.config.get('Profile'));
    // console.log(oNFTTxData.get_fcl_arg().value.fields);

    const txRawData = await execScripts({
        flowService: fs_owner, 
        script_path: "../scripts/getRawTxData.cdc", 
        args: [
            oNFTTxData.get_fcl_arg()
        ]
    });

    // console.log(toBeSign);
    oNFTTxData.signature = new Uint8Array(ownerOC.sign2buffer(Buffer.from(txRawData, "hex")));
    // console.log(ownerOC.sign2hexstring(Buffer.from(txRawData, "hex")));
    // console.log(Buffer.from(oNFTTxData.signature).toString("hex"));

    // test
    // await testSignature(ownerOC.getPublic().substring(2), txRawData, Buffer.from(oNFTTxData.signature).toString("hex"));
    // test end

    let response = await sendTransaction({flowService: fs_owner, 
                                            tx_path: "../transactions/mintNFT.cdc", 
                                            args: [oNFTTxData.get_fcl_arg()]});

    let rst = await settlement(response);
    if (true == rst.status) {
        console.log(rst.data.events[0].data);
    }
}

async function claimNFTs(account) {
    const op_fs = fs_map[account];
    const op_oc = new oc.OmnichainCrypto(keccak256, 'secp256k1', op_fs.signerPrivateKeyHex);

    const response = await sendTransaction({
        flowService: op_fs,
        tx_path: "../transactions/claimNFT.cdc",
        args: [
            fcl.arg(Array.from(Buffer.from(op_oc.getPublic().substring(2), 'hex')).map((item) => {return String(item)}), types.Array(types.UInt8))
        ]
    });

    const rst = await settlement(response);
    console.log(`Claim NFT for ${account}: ${rst.data.statusString}`);
}

async function checkNFTs(account) {
    const op_fs = fs_map[account];

    const op_oc = new oc.OmnichainCrypto(keccak256, 'secp256k1', op_fs.signerPrivateKeyHex);

    const nfts = await execScripts({
        flowService: op_fs,
        script_path: "../scripts/checkNFTs.cdc",
        args: [
            fcl.arg(Array.from(Buffer.from(op_oc.getPublic().substring(2), 'hex')).map((item) => {return String(item)}), types.Array(types.UInt8))
        ]
    });

    // console.log(nfts);

    return nfts;
}

async function nftOwnerships() {
    const keys = Object.keys(fs_map);

    for (var idx = 0; idx < keys.length; ++idx) {
        await claimNFTs(keys[idx]);
    }

    for (var idx = 0; idx < keys.length; ++idx) {
        console.log(`NFTs owned by ${keys[idx]}: ${await checkNFTs(keys[idx])}`);
    }
}

async function nftAutoTest() {
    // initialize environment
    await checkSimuAccounts();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await setLockPeriod('10.0');
    await new Promise(resolve => setTimeout(resolve, 1000));
    await checkLockPeriod();

    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log('-----------------Mint two NFTs to `owner`-----------------')
    await nftMint();
    await nftMint();

    console.log('*****************Before Waiting Time**********************');
    await nftOwnerships();
    await new Promise(resolve => setTimeout(resolve, 15000));

    console.log('#################After Waiting Time######################');

    await sendEmptyTx();

    await nftOwnerships();
    await new Promise(resolve => setTimeout(resolve, 1000));
    const nftInOwner = await checkNFTs('owner');
    console.log(`-----------------'owner' transfer NFT ${nftInOwner[0]} to 'Alice', NFT ${nftInOwner[1]} to 'Bob'-----------------`);
    await nftTransfer('owner', 'Alice', nftInOwner[0]);
    await nftTransfer('owner', 'Bob', nftInOwner[1]);

    console.log('*****************Before Waiting Time**********************');
    await nftOwnerships();
    await new Promise(resolve => setTimeout(resolve, 15000));
    console.log('#################After Waiting Time######################');
    await nftOwnerships();

    await new Promise(resolve => setTimeout(resolve, 1000));
    var nftInAlice = await checkNFTs('Alice');
    var nftInBob = await checkNFTs('Bob');
    console.log(`-----------------'Alice' transfer NFT ${nftInAlice[0]} to 'Carl'-----------------`);
    console.log(`-----------------'Bob' burn his NFT ${nftInBob[0]}-----------------`);
    await nftTransfer('Alice', 'Carl', nftInAlice[0]);
    await nftBurn('Bob', nftInBob[0]);

    console.log('*****************Before Waiting Time**********************');
    await nftOwnerships();
    await new Promise(resolve => setTimeout(resolve, 15000));
    console.log('#################After Waiting Time######################');
    await nftOwnerships();
}

function list(val) {
    if (val == undefined) {
        return [];
    } else {
        return val.split(',');
    }
}

function list_line(val) {
    return val.split('|');
}

async function commanders() {
    program
        .version('Test Tools for omniverse Flow. v0.0.1')
        .option('--check-accounts', 'Check the simulation accounts')
        .option('--set-members <members>', 'Set the member chains of the Omniverse NFT', list_line)
        .option('--check-members', 'Check the allowed members')
        .option('--set-lock-period <period>', 'Set the cooling time', list_line)
        .option('--check-lock-period', 'Check the cooling time')
        .option('--nft-mint', 'mint an omniverse NFT to the owner account')
        .option('--nft-transfer <from>,<to>,<tokenId>', 'transfer an NFT with id `tokenId` from `from` to `to`', list)
        .option('--nft-burn <from>,<tokenId>', '`from` burns an NFT with id `tokenId`', list)
        .option('--check-nfts <role>', 'Check the NFTs owned by the `role`', list)
        .option('--claim-nfts <role>', 'Claim the NFTs held in the shelter owned by the `role`', list)
        .option('--nft-auto-test', 'make the autotest of the ERC-6358 NFTs')
        .parse(process.argv);
        
    if (program.opts().setMembers) {
        if (program.opts().setMembers.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().setMembers.length + ' provided');
            return;
        }

        await setMembers(...program.opts().setMembers);
    } else if (program.opts().checkMembers) {
        await checkMembers();
    } else if (program.opts().setLockPeriod) {
        if (program.opts().setLockPeriod.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().setLockPeriod.length + ' provided');
            return;
        }

        await setLockPeriod(...program.opts().setLockPeriod);
    } else if (program.opts().checkLockPeriod) {
        await checkLockPeriod();
    } else if (program.opts().checkAccounts) {
        await checkSimuAccounts();
    } else if (program.opts().nftMint) {
        await nftMint();
    } else if (program.opts().checkNfts) {
        if (program.opts().checkNfts.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().checkNfts.length + ' provided');
            return;
        }

        const nfts = await checkNFTs(...program.opts().checkNfts);
        console.log(nfts);

    } else if (program.opts().claimNfts) {
        if (program.opts().claimNfts.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().claimNfts.length + ' provided');
            return;
        }

        await claimNFTs(...program.opts().claimNfts);

    } else if (program.opts().nftTransfer) {
        if (program.opts().nftTransfer.length != 3) {
            console.log('3 arguments are needed, but ' + program.opts().nftTransfer.length + ' provided');
            return;
        }

        await nftTransfer(...program.opts().nftTransfer);

    } else if (program.opts().nftBurn) {
        if (program.opts().nftBurn.length != 2) {
            console.log('2 arguments are needed, but ' + program.opts().nftBurn.length + ' provided');
            return;
        }

        await nftBurn(...program.opts().nftBurn);
    } else if (program.opts().nftAutoTest) {
        await nftAutoTest();
    }
}

await commanders();
