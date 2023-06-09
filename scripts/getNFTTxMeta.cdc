// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

pub struct NFTTxMeta {
    pub let nonce: UInt128;
    pub let nextNFTId: UInt256;
    pub let flowChainId: UInt32;
    pub let contractName: String;

    init(nonce: UInt128, nextNFTId: UInt256, flowChainId: UInt32, contractName: String) {
        self.nonce = nonce;
        self.nextNFTId = nextNFTId;
        self.flowChainId = flowChainId;
        self.contractName = contractName;
    }
}

pub fun main(from: [UInt8]): NFTTxMeta {
    return NFTTxMeta(nonce: ERC6358NFTExample.getWorkingNonce(pk: from), nextNFTId: ERC6358NFTExample.getNextMintID(), flowChainId: ERC6358NFTExample.flowChainID, contractName: ERC6358NFTExample.contractName);
}
