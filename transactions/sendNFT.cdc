// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";
// import IERC6358Token from "../contracts/IERC6358Token.cdc";
// import ERC6358Protocol from ../contracts/ERC6358Protocol.cdc;

// node
import ERC6358Protocol from 0xf8d6e0586b0a20c7;
import IERC6358Token from 0xf8d6e0586b0a20c7;
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

transaction(txData: AnyStruct{IERC6358Token.IERC6358TxProtocol}){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        let op_address = ERC6358Protocol.getFlowAddress(pubKey: txData.from);
        let op_collection = ERC6358Protocol.getIERC6358Operation(addr: op_address, contractName: ERC6358NFTExample.contractName);

        op_collection.sendOmniverseTransaction(otx: txData);
    }
}
