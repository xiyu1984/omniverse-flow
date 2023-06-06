import {FlowService, settlement, sendTransaction, execScripts} from './scaffold/flowoffchain.mjs'
import fcl from '@onflow/fcl';
import * as types from "@onflow/types";
import { SHA3 } from 'sha3';

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
        .option('--set-members <members>', 'Get different kinds of accounts from public key', list_line)
        .option('--check-members', 'Check the allowed members')
        .parse(process.argv);
        
    if (program.opts().setMembers) {
        if (program.opts().setMembers.length != 1) {
            console.log('1 arguments are needed, but ' + program.opts().setMembers.length + ' provided');
            return;
        }

        await setMembers(...program.opts().setMembers);
    } else if (program.opts().checkMembers) {
        await checkMembers();
    }
}

await commanders();
