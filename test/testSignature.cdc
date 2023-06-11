// import ERC6358Protocol from "../contracts/ERC6358Protocol.cdc";

import ERC6358Protocol from 0xf8d6e0586b0a20c7;

pub fun main(pk: String, rawData: String, signature: String): Bool {
    return ERC6358Protocol.rawSignatureVerify(pubKey: pk.decodeHex(), rawData: rawData.decodeHex(), signature: signature.decodeHex(), hashAlgorithm: HashAlgorithm.KECCAK_256);
}
