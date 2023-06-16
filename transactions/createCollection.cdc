// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";
// import NonFungibleToken from "../contracts/NonFungibleToken.cdc";;

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;
import NonFungibleToken from 0xf8d6e0586b0a20c7;

transaction(){
    let signer: AuthAccount;

    prepare(signer: AuthAccount){
        self.signer = signer
    }

    execute {
        let collection <- ERC6358NFTExample.createEmptyCollection();
        self.signer.save(<- collection, to: ERC6358NFTExample.CollectionStoragePath);
        self.signer.link<&{NonFungibleToken.CollectionPublic}>(ERC6358NFTExample.CollectionPublicPath, target: ERC6358NFTExample.CollectionStoragePath)
    }
}