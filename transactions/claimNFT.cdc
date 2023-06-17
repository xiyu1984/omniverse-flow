// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

transaction(pubKey: [UInt8]){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        ERC6358NFTExample.claimOmniverseNFTs(recvPk: pubKey);
    }
}
