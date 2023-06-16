// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";
// import ERC6358Protocol from "../contracts/ERC6358Protocol.cdc";

// node
import ERC6358Protocol from 0xf8d6e0586b0a20c7;
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

pub fun main(pk: [UInt8]): [UInt64] {
    let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: pk);
    let cp = ERC6358NFTExample.getCollectionPublic(addr: flowAddress);
    return cp!.getIDs();
}