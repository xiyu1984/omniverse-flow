// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

transaction(members: {UInt32: String}){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        let modifier = self.signer.borrow<&ERC6358NFTExample.Modifier>(from: ERC6358NFTExample.ModifierPath)!;
        modifier.allowedMembers = members;
    }
}
