import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ERC6358Protocol from "./ERC6358Protocol.cdc"
import IERC6358Token from "./IERC6358Token.cdc"
import BasicUtility from "./utility/BasicUtility.cdc";

pub contract ERC6358NFTExample: NonFungibleToken, IERC6358Token{
    
    pub var totalSupply: UInt64;                            // The total number of tokens of this type in existence
    priv var _nextMintID: UInt256;                          // The ID of `ERC6358NFTExample` is automatically assigned

    pub let CollectionStoragePath: StoragePath;
    pub let CollectionPublicPath: PublicPath;

    pub let flowChainID: UInt32;
    pub let contractName: String;

    pub let allowedMembers: {UInt32: String};               // value is generated by `String.encodeHex(contract address: [UInt8])`
    pub let lockPeriod: UFix64;                             // In current version, there needs to be a wait time for omniverse transactions to be executed

    priv let transactionRecorder: {Address: ERC6358Protocol.RecordedCertificate};    // key is the address of a flow account, which is recorded in `ERC6358Protocol._pk2address_map`
    priv let TokenShelter: @{String: [{IERC6358Token.IERC6358TokenExec}]};          // Store pending tokens. The key is the recv address generated by `String.encodeHex(recver: [UInt8])`
    priv let Prisons: @{String: [{IERC6358Token.IERC6358TokenExec}]};               // Store punishment NFTs. The key is the operating address generated by `String.encodeHex(operator: [UInt8])`
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    pub event ContractInitialized()                         // Event that emitted when the NFT contract is initialized
    pub event Withdraw(id: UInt64, from: Address?)          // Event that is emitted when a token is withdrawn,
    pub event Deposit(id: UInt64, to: Address?)             // Event that emitted when a token is deposited to a collection.

    ////////////////////////////////////
    // Events for Omniverse Transactions
    pub event OmniverseTxEvent(pk: [UInt8], nonce: UInt128, result: Bool, description: String);      // Omniverse Transactions Information

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Omniverse definations
    pub struct OmniverseNFTPayload: IERC6358Token.IERC6358Payload {
        // 0: Omniverse Transfer
        // 1: Omniverse mint. When minting, the `tokenId` is useless
        // 2: Omniverse burn
        pub let operation: UInt8;
        pub let exData: [UInt8];

        pub let tokenId: UInt256;

        init(operation: UInt8, exData: [UInt8], tokenId: UInt256) {
            self.operation = operation;
            self.exData = exData;
            self.tokenId = tokenId;
        }

        pub fun toBytes(): [UInt8] {
            var output: [UInt8] = [];

            output.append(self.operation);
            output = output.concat(self.exData);
            output = output.concat(BasicUtility.to_be_bytes_u256(self.tokenId));

            return output;
        }
    }

    pub struct OmniverseNFTProtocol: IERC6358Token.IERC6358TxProtocol {
        pub let nonce: UInt128;

        // The chain where the o-transaction is initiated
        pub let chainid: UInt32;
        // The contract address from which the o-transaction is first initiated
        // on Flow, this is concat by `account address`+`contract name`
        pub let initiateSC: String;
        // The Omniverse account which signs the o-transaction
        pub let from: [UInt8];

        pub let payload: AnyStruct{IERC6358Token.IERC6358Payload};

        pub let signature: [UInt8];

        init(nonce: UInt128, chainid: UInt32, initiateSC: String, from: [UInt8], payload: AnyStruct{IERC6358Token.IERC6358Payload}, signature: [UInt8]) {
            self.nonce = nonce;
            self.chainid = chainid;
            self.initiateSC = initiateSC;
            self.from = from;
            self.payload = payload;
            self.signature = signature;
        }

        // pub fun toBytesExceptNonce(): [UInt8];
        pub fun toBytes(): [UInt8] {
            var output: [UInt8] = [];

            output = output.concat(BasicUtility.to_be_bytes_u128(self.nonce));
            output = output.concat(self.chainid.toBigEndianBytes());
            output = output.concat(self.initiateSC.utf8);
            output = output.concat(self.from);
            output = output.concat(self.payload.toBytes());

            return output;
        }
        // pub fun getOperateIdentity(): [UInt8];
    }

    // Omniverse NFT
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, IERC6358Token.IERC6358TokenExec {
        pub let id: UInt64;
        
        access(account) var lockedTime: UFix64;

        // Information
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}

        access(contract) init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
        ) {

            self.lockedTime = 0.0

            // Information
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
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
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Example NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ERC6358NFTExample.CollectionStoragePath,
                        publicPath: ERC6358NFTExample.CollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&ERC6358NFTExample.Collection{NonFungibleToken.CollectionPublic}>(),
                        publicLinkedType: Type<&ERC6358NFTExample.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ERC6358NFTExample.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ERC6358NFTExample.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Example Collection",
                        description: "This collection is used as an example to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    // foo is a trait with its own rarity
                    let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                    traitsView.addTrait(fooTrait)
                    
                    return traitsView

            }
            return nil
        }

        access(account) fun setLockedTime() {
            self.lockedTime = getCurrentBlock().timestamp;
        }

        pub fun getLockedTime(): UFix64{
            return self.lockedTime;
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, IERC6358Token.IERC6358Operation {
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
            let exampleNFT = nft as! &ERC6358NFTExample.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        ////////////////////////////////////////////
        // Operations of ERC6358 defination for Flow
        // Operations include transferring and burning
        pub fun sendOmniverseTransaction(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}) {
            let fromAddress = ERC6358Protocol.getFlowAddress(pubKey: otx.from);

            // check `from` address
            if (self.owner!.address != fromAddress) {
                panic("Unauthorized Sender!");
            }

            // check id
            var tokenId: UInt256? = nil;
            if let dataPayload: OmniverseNFTPayload = otx.payload as? OmniverseNFTPayload {
                if (!self.ownedNFTs.containsKey(UInt64(dataPayload.tokenId))) {
                    panic("Token ID does not exist!");
                } else {
                    tokenId = dataPayload.tokenId;
                }
            } else {
                panic("Invalid payload data structure!");
            }

            // verify message signature
            if (!ERC6358NFTExample._omniverseTxPublish(otx: otx)) {
                // panic("Invalid omniverse `mint` transaction!");
                log("Invalid omniverse `mint` transaction!");
                return;
            }

            // do operations
            if (otx.payload.operation == 0) {
                self._delayedTransfer(otx: otx, id: tokenId!);
            } else if (otx.payload.operation == 2) {
                self._delayedBurn(otx: otx, id: tokenId!);
            } else {
                panic("Invalid Operation!");
            }
        }

        // Not in the `EIP-6358` standard, but necessary in Flow
        access(account) fun omniverseExec(omniToken: @AnyResource{IERC6358Token.IERC6358TokenExec}) {
            let nft <- omniToken as! @NonFungibleToken.NFT;
            // let nft <- temp as! @NonFungibleToken.NFT;

            self.ownedNFTs[nft.id] <-! nft;
        }

        ////////////////////////////////////////////
        // inner functions
        priv fun _delayedTransfer(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}, id: UInt256) {
            let nft <- self.ownedNFTs.remove(key: UInt64(id)) ?? panic("missing NFT");
            let omniverseToken <- (nft as! @NFT);

            ERC6358NFTExample._addPendingToken(recvIdentity: otx.payload.exData, token: <- omniverseToken);

            emit OmniverseTxEvent(pk: otx.from, nonce: otx.nonce, result: true, description: "Omniverse Transfer being Successfully Submitted!");
        }

        priv fun _delayedBurn(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}, id: UInt256) {
            let nft <- self.ownedNFTs.remove(key: UInt64(id)) ?? panic("missing NFT");
            let omniverseToken <- (nft as! @NFT);

            ERC6358NFTExample._addPendingToken(recvIdentity: [0], token: <- omniverseToken);

            emit OmniverseTxEvent(pk: otx.from, nonce: otx.nonce, result: true, description: "Omniverse Burn being Successfully Submitted!");
        }
    }

    init() {
        self.totalSupply = 0;
        self._nextMintID = 0;

        self.flowChainID = 7;
        self.contractName = self.account.address.toString().concat(".ERC6358NFTExample");

        self.allowedMembers = {};
        self.transactionRecorder = {}
        self.TokenShelter <- {}
        self.Prisons <- {}
        self.lockPeriod = 10.0 * 60.0;

        self.CollectionStoragePath = /storage/ERC6358NFTExampleCollection;
        self.CollectionPublicPath = /public/ERC6358NFTExampleCollection;
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    ////////////////////////////////////////////
    // Public Omniverse Operations
    pub fun omniverseMint(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}) {
        let fromAddress = ERC6358Protocol.getFlowAddress(pubKey: otx.from);
        
        // check `from` is the owner
        if (self.account.address != fromAddress) {
            panic("Only Owner Can mint!");
        }

        // verify message signature
        if (!self._omniverseTxPublish(otx: otx)) {
            // panic("Invalid omniverse `mint` transaction!");
            log("Invalid omniverse `mint` transaction!");
            return;
        }

        // check the token ID
        if let dataPayload: OmniverseNFTPayload = otx.payload as? OmniverseNFTPayload {
            if (self._nextMintID != dataPayload.tokenId) {
                panic("Invalid token id, and the currently valid one is: ".concat(self._nextMintID.toString()));
            }
        } else {
            panic("Invalid payload data structure!");
        }

        // mint a token and add into the `TokenShelter`
        let nft <- create NFT(id: UInt64(self._nextMintID),
                                name: "Omniverse-Example-NFT",
                                description: "Omniverse-Example-NFT",
                                thumbnail: "https://raw.githubusercontent.com/xiyu1984/hamster-nft/main/test/metadata/0",
                                royalties: [],
                                metadata: {});

        self._addPendingToken(recvIdentity: otx.payload.exData, token: <- nft);

        // After everything is OK
        self._nextMintID = self._nextMintID + 1;

        emit OmniverseTxEvent(pk: otx.from, nonce: otx.nonce, result: true, description: "Omniverse Mint being Successfully Submitted!");
    }

    pub fun getTransactionCount(pk: [UInt8]): UInt128 {
        let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: pk);
        if let rc = self.transactionRecorder[flowAddress] {
            return rc.getTransactionCount();
        } else {
            return UInt128(0);
        }
    }

    pub fun getTransactionData(user: [UInt8], nonce: UInt128): AnyStruct{IERC6358Token.IERC6358TxData} {
        let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: user);
        if let rc = self.transactionRecorder[flowAddress] {
            return rc.getTransactionData(nonce: nonce);
        }

        panic("Omniverse Transaction with nonce ".concat(nonce.toString()).concat(" does not exist!"));
    }

    pub fun getNextMintID(): UInt256{
        return self._nextMintID;
    }

    pub fun getWorkingNonce(pk: [UInt8]): UInt128 {
        let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: pk);

        if let rc = self.transactionRecorder[flowAddress] {
            return rc.getWorkingNonce();
        } else {
            return UInt128(0);
        }
    }

    pub fun claimOmniverseNFTs(recvPk: [UInt8]) {
        let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: recvPk);

        self.checkValid(opAddressOnFlow: flowAddress);

        let recvCollection = ERC6358Protocol.getIERC6358Operation(addr: flowAddress, contractName: self.contractName);

        if let shelter = &self.TokenShelter[String.encodeHex(recvPk)] as &[{IERC6358Token.IERC6358TokenExec}]? {
            var idx = shelter.length;
            while idx > 0 {
                let idx = idx - 1;
                if (getCurrentBlock().timestamp - shelter[idx].getLockedTime()) > self.lockPeriod {
                    let pendedNFT <- shelter.remove(at: idx);
                    recvCollection.omniverseExec(omniToken: <- pendedNFT);
                }
            }
        }

        panic("There are not any NFTs to be claimed!");
    }

    pub fun checkValid(opAddressOnFlow: Address): Bool {
        if let rc = (&self.transactionRecorder[opAddressOnFlow] as &ERC6358Protocol.RecordedCertificate?) {
            if rc.isMalicious() {
                panic("The address did malicious things and has been locked now!");
            }
        }

        return true;
    }

    ////////////////////////////////////////////
    // self functions
    access(contract) fun _omniverseTxPublish(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}): Bool {
        // check signature
        if (!ERC6358Protocol.rawSignatureVerify(pubKey: otx.from, rawData: otx.toBytes(), signature: otx.signature, hashAlgorithm: HashAlgorithm.KECCAK_256)) {
            panic("Invalid signature for the omniverse Tx");
        }

        let flowAddress = ERC6358Protocol.getFlowAddress(pubKey: otx.from);

        // check nonce
        if let ownerRC = (&self.transactionRecorder[flowAddress] as &ERC6358Protocol.RecordedCertificate?) {
            let workingNonce = ownerRC.getWorkingNonce();
            if (workingNonce == otx.nonce) {
                // current nonce
                // ownerRC.makeNextNonce();
                ownerRC.addTx(tx: ERC6358Protocol.OmniverseTxData(txData: otx));
            } else if (workingNonce > otx.nonce) {
                // history nonce
                return self._checkConflict(otx: otx, rc: ownerRC);
            } else {
                // future nonce
                panic("Invalid nonce. Related PK: ".concat(String.encodeHex(otx.from)));
            }
        } else {
            if (UInt128(0) == otx.nonce) {
                let rc = ERC6358Protocol.RecordedCertificate(addressOnFlow: flowAddress);
                rc.addTx(tx: ERC6358Protocol.OmniverseTxData(txData: otx))
                self.transactionRecorder[flowAddress] = rc;
            } else {
                panic("Invalid nonce. Related PK: ".concat(String.encodeHex(otx.from)));
            }
        }

        return true;
    }

    priv fun _checkConflict(otx: AnyStruct{IERC6358Token.IERC6358TxProtocol}, rc: &ERC6358Protocol.RecordedCertificate): Bool {
        let historyTx = rc.publishedTx[otx.nonce];
        if historyTx.txData.nonce != otx.nonce {
            panic("Nonce-index mechanism failed!");
        }

        let otxHash = String.encodeHex(HashAlgorithm.KECCAK_256.hash(otx.toBytes()));
        if (historyTx.hash == otxHash) {
            return true;
        } else {
            rc.setMalicious(historyTx: historyTx, currentTx: ERC6358Protocol.OmniverseTxData(txData: otx));
            // Here we will lock the @token added to `TokenShelter` in the past, so we need to use `historyTx.txData`
            self._lockedUpInPrison(otx: &historyTx.txData as! &AnyStruct{IERC6358Token.IERC6358TxProtocol});

            emit OmniverseTxEvent(pk: otx.from, nonce: otx.nonce, result: false, description: "Double Spend Attack!");
            return false;
        }
    }

    access(contract) fun _addPendingToken(recvIdentity: [UInt8], token: @{IERC6358Token.IERC6358TokenExec}) {
        token.setLockedTime();
        let recvStr = String.encodeHex(recvIdentity);
        if let shelter = (&self.TokenShelter[recvStr] as &[{IERC6358Token.IERC6358TokenExec}]?) {
            shelter.append(<- token);
        } else {
            self.TokenShelter[recvStr] <-! [<-token];
        }
    }

    priv fun _takeout(id: UInt64, container: &[{IERC6358Token.IERC6358TokenExec}]): @{IERC6358Token.IERC6358TokenExec}? {
        let count = container.length;
        var idx = 0;
        while idx < count {
            let tempRef = &container[idx] as! auth &{IERC6358Token.IERC6358TokenExec};
            let storedToken = tempRef as! &ERC6358NFTExample.NFT;

            if storedToken.id == id {
                return <- container.remove(at: idx);
            }
            
            idx = idx + 1;
        }

        return nil;
    }

    priv fun _lockedUpInPrison(otx: &AnyStruct{IERC6358Token.IERC6358TxProtocol}) {
        let nftPayload = otx.payload as! ERC6358NFTExample.OmniverseNFTPayload;
        // The recver
        let recverStr = String.encodeHex(nftPayload.exData);
        // The malicious operator
        let opStr = String.encodeHex(otx.from);

        if let container = (&self.TokenShelter[recverStr] as &[{IERC6358Token.IERC6358TokenExec}]?) {
            if let token <- self._takeout(id: UInt64(nftPayload.tokenId), container: container) {
                if let prisons = (&self.Prisons[opStr] as &[{IERC6358Token.IERC6358TokenExec}]?) {
                    prisons.append(<- token);
                } else {
                    self.Prisons[opStr] <-! [<- token];
                }
            }
        }
    }
}
 