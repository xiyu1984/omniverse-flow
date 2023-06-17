// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";
// import NonFungibleToken from "../contracts/NonFungibleToken.cdc";
// import IERC6358Token from "../contracts/IERC6358Token.cdc";
// import ERC6358Protocol from "../contracts/ERC6358Protocol.cdc";

// node
import ERC6358Protocol from 0xf8d6e0586b0a20c7;
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;
import NonFungibleToken from 0xf8d6e0586b0a20c7;
import IERC6358Token from 0xf8d6e0586b0a20c7;

transaction(){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        let collection <- ERC6358NFTExample.createEmptyCollection();
        self.signer.save(<- collection, to: ERC6358NFTExample.CollectionStoragePath);
        self.signer.link<&{NonFungibleToken.CollectionPublic}>(ERC6358NFTExample.CollectionPublicPath, target: ERC6358NFTExample.CollectionStoragePath);

        // log(ERC6358Protocol.IERC6358PathPrefix.concat(ERC6358NFTExample.contractName));

        let erc6358OPPath = PublicPath(identifier: ERC6358Protocol.IERC6358PathPrefix.concat(ERC6358NFTExample.contractName))!;
        self.signer.link<&{IERC6358Token.IERC6358Operation}>(erc6358OPPath, target: ERC6358NFTExample.CollectionStoragePath)
    }
}
