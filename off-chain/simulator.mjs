import {FlowService, settlement, sendTransaction, execScripts} from './scaffold-flow/flowoffchain.mjs'
import fcl, { send } from '@onflow/fcl';
import * as types from "@onflow/types";
import { SHA3 } from 'sha3';
import keccak256 from 'keccak256';

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
                                    'p256');

const fsAlice = new FlowService('0x01cf0e2f2f715450', 
                                    'c9193930b34dd498378e36c35118a627d9eb500f6fd69b16d8e59db7cc8f5bb3',
                                    0,
                                    sha3_256FromString,
                                    'p256');

const fsBob = new FlowService('0x179b6b1cb6755e31', 
                                    'd95472318e773b2046b078ae252c42082752c7b7876ce2770a2d3e00b02bbed5',
                                    0,
                                    sha3_256FromString,
                                    'p256');

async function setMembers(members) {
    // console.log(members);
    // let fcl_arg = fcl.arg([{key: 1, value: "one"}, {key: 2, value: "two"}], types.Dictionary({key: types.UInt32, value: types.String}));
    let fcl_arg = fcl.arg(JSON.parse(members), types.Dictionary({key: types.UInt32, value: types.String}));

    let response = await sendTransaction({flowService: fs_owner, tx_path: "../transactions/setMembers.cdc", args: [fcl_arg]});

    await settlement(response);
}

async function checkMembers() {
    let rstData = await execScripts({flowService: fs_owner, script_path: "../scripts/getMembers.cdc", args: []});

    console.log(rstData);
}

async function setLockPeriod(period) {
    let fcl_arg = fcl.arg(period, types.UFix64);

    await settlement(await sendTransaction({flowService: fs_owner, tx_path: "../transactions/setLockPeriod.cdc", args: [fcl_arg]}));
}

async function checkLockPeriod() {
    console.log(await execScripts({flowService: fs_owner, script_path: "../scripts/getLockPeriod.cdc", args: []}));
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
        .option('--set-members <members>', 'Set the member chains of the Omniverse NFT', list_line)
        .option('--check-members', 'Check the allowed members')
        .option('--set-lock-period <period>', 'Set the cooling time', list_line)
        .option('--check-lock-period', 'Check the cooling time')
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
    }
}

await commanders();
