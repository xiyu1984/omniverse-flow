import * as fcl from '@onflow/fcl';
import * as types from "@onflow/types";

export enum opType {
    o_transfer = 0,
    o_mint,
    o_burn
}

export class OmniverseNFTPayload {
    operation: opType;
    exData: Uint8Array;
    tokenId: string;
    id: string;

    constructor(op: opType, exData: Uint8Array | Buffer, tokenId: string, moduleAddress: string) {
        this.operation = op;
        this.exData = exData;
        this.tokenId = tokenId;

        if (moduleAddress.startsWith('0x')) {
            this.id = 'A.' + moduleAddress.slice(2) + '.ERC6358NFTExample.OmniverseNFTPayload';
        } else {
            this.id = 'A.' + moduleAddress + '.ERC6358NFTExample.OmniverseNFTPayload';
        }
    }

    get_fcl_arg() {

        return fcl.arg({
            fields: [
              {name: "operation", value: String(this.operation)},
              {name: "exData", value: Array.from(this.exData).map((num: number) => {return String(num);})},
              {name: "tokenId", value: this.tokenId}
            ]
        }, types.Struct(this.id, [
            {name: "operation", value: types.UInt8},
            {name: "exData", value: types.Array(types.UInt8)},
            {name: "tokenId", value: types.UInt256}
        ]));
    }

    get_value() {
        return {
            fields: [
                {name: "operation", value: String(this.operation)},
                {name: "exData", value: Array.from(this.exData).map((num: number) => {return String(num);})},
                {name: "tokenId", value: this.tokenId}
            ]   
        }
    }

    get_type() {
        return types.Struct(this.id, [
            {name: "operation", value: types.UInt8},
            {name: "exData", value: types.Array(types.UInt8)},
            {name: "tokenId", value: types.UInt256}
        ]);
    }

    static type_trait(moduleAddress: string) {
        var id;
        if (moduleAddress.startsWith('0x')) {
            id = 'A.' + moduleAddress.slice(2) + '.ERC6358NFTExample.OmniverseNFTPayload';
        } else {
            id = 'A.' + moduleAddress + '.ERC6358NFTExample.OmniverseNFTPayload';
        }

        return types.Struct(id, [
            {name: "operation", value: types.UInt8},
            {name: "exData", value: types.Array(types.UInt8)},
            {name: "tokenId", value: types.UInt256}
        ]);
    }
}

export class OmniverseNFTProtocol {

}
