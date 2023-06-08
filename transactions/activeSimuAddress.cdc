// import ERC6358Protocol from "../contracts/ERC6358Protocol.cdc";

// node
import ERC6358Protocol from 0xf8d6e0586b0a20c7;

transaction(addr: Address){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        ERC6358Protocol.activeOmniverse(addressOnFlow: addr);
    }
}