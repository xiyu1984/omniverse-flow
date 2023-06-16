// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";
// import IERC6358Token from "../contracts/IERC6358Token.cdc";

// node
import IERC6358Token from 0xf8d6e0586b0a20c7;
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

transaction(txData: AnyStruct{IERC6358Token.IERC6358TxProtocol}){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        ERC6358NFTExample.omniverseMint(otx: txData);
    }
}
