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
    return OmniverseNFTPayload;
}());
exports.OmniverseNFTPayload = OmniverseNFTPayload;
var OmniverseNFTProtocol = /** @class */ (function () {
    function OmniverseNFTProtocol() {
    }
    return OmniverseNFTProtocol;
}());
exports.OmniverseNFTProtocol = OmniverseNFTProtocol;
