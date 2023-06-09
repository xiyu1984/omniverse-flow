"use strict";
exports.__esModule = true;
exports.OmniverseNFTProtocol = exports.OmniverseNFTPayload = exports.opType = void 0;
var fcl = require("@onflow/fcl");
var types = require("@onflow/types");
var opType;
(function (opType) {
    opType[opType["o_transfer"] = 0] = "o_transfer";
    opType[opType["o_mint"] = 1] = "o_mint";
    opType[opType["o_burn"] = 2] = "o_burn";
})(opType = exports.opType || (exports.opType = {}));
var OmniverseNFTPayload = /** @class */ (function () {
    function OmniverseNFTPayload(op, exData, tokenId, moduleAddress) {
        this.operation = op;
        this.exData = exData;
        this.tokenId = tokenId;
        if (moduleAddress.startsWith('0x')) {
            this.id = 'A.' + moduleAddress.slice(2) + '.ERC6358NFTExample.OmniverseNFTPayload';
        }
        else {
            this.id = 'A.' + moduleAddress + '.ERC6358NFTExample.OmniverseNFTPayload';
        }
    }
    OmniverseNFTPayload.prototype.get_fcl_arg = function () {
        return fcl.arg({
            fields: [
                { name: "operation", value: String(this.operation) },
                { name: "exData", value: Array.from(this.exData).map(function (num) { return String(num); }) },
                { name: "tokenId", value: this.tokenId }
            ]
        }, types.Struct(this.id, [
            { name: "operation", value: types.UInt8 },
            { name: "exData", value: types.Array(types.UInt8) },
            { name: "tokenId", value: types.UInt256 }
        ]));
    };
    OmniverseNFTPayload.prototype.get_value = function () {
        return {
            fields: [
                { name: "operation", value: String(this.operation) },
                { name: "exData", value: Array.from(this.exData).map(function (num) { return String(num); }) },
                { name: "tokenId", value: this.tokenId }
            ]
        };
    };
    OmniverseNFTPayload.prototype.get_type = function () {
        return types.Struct(this.id, [
            { name: "operation", value: types.UInt8 },
            { name: "exData", value: types.Array(types.UInt8) },
            { name: "tokenId", value: types.UInt256 }
        ]);
    };
    OmniverseNFTPayload.type_trait = function (moduleAddress) {
        var id;
        if (moduleAddress.startsWith('0x')) {
            id = 'A.' + moduleAddress.slice(2) + '.ERC6358NFTExample.OmniverseNFTPayload';
        }
        else {
            id = 'A.' + moduleAddress + '.ERC6358NFTExample.OmniverseNFTPayload';
        }
        return types.Struct(id, [
            { name: "operation", value: types.UInt8 },
            { name: "exData", value: types.Array(types.UInt8) },
            { name: "tokenId", value: types.UInt256 }
        ]);
    };
    return OmniverseNFTPayload;
}());
exports.OmniverseNFTPayload = OmniverseNFTPayload;
var OmniverseNFTProtocol = /** @class */ (function () {
    function OmniverseNFTProtocol(nonce, chainid, initSC, from, payload, moduleAddress) {
        this.nonce = nonce;
        this.chainid = chainid;
        this.initiateSC = initSC;
        this.from = from;
        this.payload = payload;
        this.signature = new Uint8Array();
        if (moduleAddress.startsWith('0x')) {
            this.id = 'A.' + moduleAddress.slice(2) + '.ERC6358NFTExample.OmniverseNFTProtocol';
        }
        else {
            this.id = 'A.' + moduleAddress + '.ERC6358NFTExample.OmniverseNFTProtocol';
        }
    }
    OmniverseNFTProtocol.prototype.get_fcl_arg = function () {
        return fcl.arg({
            fields: [
                { name: "nonce", value: this.nonce },
                { name: "chainid", value: this.chainid },
                { name: "initiateSC", value: this.initiateSC },
                { name: "from", value: Array.from(this.from).map(function (num) { return String(num); }) },
                { name: "payload", value: this.payload.get_value() },
                { name: "signature", value: Array.from(this.signature).map(function (num) { return String(num); }) }
            ]
        }, types.Struct(this.id, [
            { name: "nonce", value: types.UInt128 },
            { name: "chainid", value: types.UInt32 },
            { name: "initiateSC", value: types.String },
            { name: "from", value: types.Array(types.UInt8) },
            { name: "payload", value: this.payload.get_type() },
            { name: "signature", value: types.Array(types.UInt8) }
        ]));
    };
    return OmniverseNFTProtocol;
}());
exports.OmniverseNFTProtocol = OmniverseNFTProtocol;
