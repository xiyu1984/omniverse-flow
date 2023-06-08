// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

pub struct NFTTxMeta {
    pub let nonce: UInt256;
    pub let nextNFTId: UInt256;

    init(nonce: UInt256, nextNFTId: UInt256) {
        self.nonce = nonce;
        self.nextNFTId = nextNFTId;
    }
}

pub fun main(from: [UInt8]): NFTTxMeta {
    return NFTTxMeta(nonce: ERC6358NFTExample.getWorkingNonce(pk: from), nextNFTId: ERC6358NFTExample.getNextMintID());
}
