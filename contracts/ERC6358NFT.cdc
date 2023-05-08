import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ERC6358Protocol from "./ERC6358Protocol.cdc"

pub contract ERC6358NFT: NonFungibleToken{
    /// The total number of tokens of this type in existence
    pub var totalSupply: UInt64

    /// Event that emitted when the NFT contract is initialized
    pub event ContractInitialized()

    /// Event that is emitted when a token is withdrawn,
    pub event Withdraw(id: UInt64, from: Address?)

    /// Event that emitted when a token is deposited to a collection.
    pub event Deposit(id: UInt64, to: Address?)

    // Omniverse NFT
    // A wrapper of a standard NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64;
        priv var lockedTime: UFix64;
        priv var iNFT: @AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}?;

        init(iNFT: @AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}) {
            self.id = iNFT.uuid;
            self.iNFT <- iNFT;
            self.lockedTime = 0.0;
        }

        pub destroy() {
            destroy self.iNFT;
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            let nftRef = (&self.iNFT as! auth &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}?)!;
            return nftRef.resolveView(view);
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {};
        }

        pub destroy() {
            destroy self.ownedNFTs;
        }
        
        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            panic("`withdraw` is deprecated in OmniverseNFT");
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            panic("`deposit` is deprecated in OmniverseNFT");
        }
        
        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &ERC6358NFT.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    init() {
        self.totalSupply = 0;
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Omniverse Operations
    pub fun omniverseMint(otx: AnyStruct{ERC6358Protocol.OmniverseTokenProtocol}, iNFT: @AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver}) {
        destroy <- iNFT;
    }
}
 