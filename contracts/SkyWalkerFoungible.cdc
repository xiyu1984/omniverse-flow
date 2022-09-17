import OmniverseProtocol from "./OmniverseProtocol.cdc";
import BasicUtility from "./utility/BasicUtility.cdc";
import FungibleToken from "./utility/FungibleToken.cdc"

pub contract SkyWalkerFoungible: FungibleToken {

    /// The total number of tokens in existence.
    /// It is up to the implementer to ensure that the total supply
    /// stays accurate and up to date
    pub var totalSupply: UFix64

    pub let contractName: String;

    // key: chainid; value: contract name
    pub let allowedContract: {String: String};
    /// TokensInitialized
    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    /// The event that is emitted when tokens are deposited into a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    pub struct OmniverseFoungible: OmniverseProtocol.OmniverseTokenProtocol {
        pub let nonce: UInt128;

        pub let chainid: String;
        pub let contractName: String;
        // resource uuid, which is the unique id for resources on Flow
        pub let amount: UFix64;
        // Flow is special, 
        // and remember to put the omniverse address in the position of first public key as the Omniverse address
        // Note that `SignatureAlgorithm.ECDSA_secp256k1` is neccessary
        pub let sender: [UInt8]?;
        pub let recver: [UInt8]?;
        // 0: Omniverse TransferFrom(like deposit)
        // 1: Transfer
        // 2: Omniverse Approve(like withdraw)
        pub let operation: UInt8;

        init(chainid: String, contractName: String, nonce: UInt128, 
                amount: UFix64, sender: [UInt8]?, recver: [UInt8]?, operation: UInt8, uuid: UInt64) {
            self.chainid = chainid;
            self.contractName = contractName;
            self.nonce = nonce;
            self.amount = amount;
            self.sender = sender;
            self.recver = recver;
            self.operation = operation;
        }

        pub fun toBytesExceptNonce(): [UInt8] {
            var output: [UInt8] = [];
            
            output = output.concat(self.chainid.utf8);
            output = output.concat(self.contractName.utf8);
            output = output.concat(BasicUtility.to_be_bytes_u256(UInt256(self.amount * 10000000.0) * 100000000000));

            if let sender = self.sender {
                output = output.concat(sender);
            }
            if let recver = self.recver {
                output = output.concat(recver);
            }

            output.append(self.operation);
            
            return output;
        }

        pub fun toBytes(): [UInt8] {
            var output: [UInt8] = [];
            
            output = output.concat(BasicUtility.to_be_bytes_u128(self.nonce));
            output = output.concat(self.toBytesExceptNonce());
            
            return output;
        }

        pub fun getOperateIdentity(): [UInt8] {
            switch self.operation {
                case UInt8(0):
                    return self.recver!;
                case UInt8(1):
                    return self.sender!;
                case UInt8(2):
                    return self.sender!;
            }

            panic("Invalid operation! Got: ".concat(self.operation.toString()));
        }

        pub fun getOmniMeta(): AnyStruct {
            return self.amount;
        }
    }

    /// Vault
    ///
    /// The resource that contains the functions to send and receive tokens.
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, OmniverseProtocol.OmniverseToken, OmniverseProtocol.OmniverseFungiblePublic {

        // The declaration of a concrete type in a contract interface means that
        // every Fungible Token contract that implements the FungibleToken interface
        // must define a concrete `Vault` resource that conforms to the `Provider`, `Receiver`,
        // and `Balance` interfaces, and declares their required fields and functions

        /// The total balance of the vault
        ///
        pub var balance: UFix64

        pub var omniverseBalance: UFix64

        access(account) var lockedTime: UFix64;

        // The conforming type must declare an initializer
        // that allows prioviding the initial balance of the Vault
        //
        init(balance: UFix64) {
            self.balance = balance;
            self.omniverseBalance = 0.0;
            self.lockedTime = 0.0;
        }

        /// withdraw subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount;
            return <- create Vault(balance: amount);
        }

        /// deposit takes a Vault and adds its balance to the balance of this Vault
        ///
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @SkyWalkerFoungible.Vault
            self.balance = self.balance + vault.balance
            // emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        ////////////////////////////////////////////////////////////////////
        /////////////////////////Omniverse//////////////////////////////////
        ////////////////////////////////////////////////////////////////////
        // OmniverseToken
        access(account) fun setLockedTime() {
            self.lockedTime = getCurrentBlock().timestamp;
        }

        pub fun getLockedTime(): UFix64 {
            return self.lockedTime;
        }

        ////////////////////////////////////////////////////////////////////
        // OmniverseFoungible
        priv fun _set_omniverse_balance(omniverseBalance: UFix64) {
            self.omniverseBalance = omniverseBalance;
        }
        ////////////////////////////////////////////////////////////////////
        // omniverse out and local in
        // omniverse out
        // @returns: a local vault(balance > 0, omniverseBalance: ignored)
        priv fun _omniverse_approve_out(amount: UFix64): @Vault {
            pre {
                (self.omniverseBalance > amount) && (amount > 0.0): 
                    "Not enough omniverse balance to be approved out!"
            }
            post {
                self.balance == before(self.balance):
                    "balance cannot be changed in `_omniverse_approve_out`"
            }

            self.omniverseBalance = self.omniverseBalance - amount;
            return <- create Vault(balance: amount);
        }

        // local in
        // @param from: a local vault(balance > 0, omniverseBalance: ignored)
        priv fun _local_transfer_in(from: @Vault) {
            pre {
                from.isInstance(self.getType()): 
                    "Cannot deposit an incompatible token type"
            }
            post {
                self.omniverseBalance == before(self.omniverseBalance):
                    "balance cannot be changed in `_local_transfer_in`"
            }

            let localVault <- from as! @SkyWalkerFoungible.Vault;
            if localVault.balance == 0.0 {
                panic("Invalid local vault");
            }

            self.balance = self.balance + localVault.balance;
            destroy localVault;
        }

        ////////////////////////////////////////////////////////////////////
        // local out and omniverse in
        // local out
        // @returns: a omniverse vault(balance: ignored, omniverseBalance > 0)
        priv fun _local_approve_out(amount: UFix64): @Vault {
            pre {
                (self.balance > amount) && (amount > 0.0): 
                    "Not enough local balance to be approved out!"
            }
            post {
                self.omniverseBalance == before(self.omniverseBalance):
                    "omniverse balance cannot be changed in `_local_approve_out`"
            }

            self.balance = self.balance - amount;
            let omniverseVault <- create Vault(balance: 0.0);
            omniverseVault._set_omniverse_balance(omniverseBalance: amount);
            return <- omniverseVault;
        }

        // omniverse transfer in
        // @param from: a omniverse vault(balance: ignored, omniverseBalance > 0)
        priv fun _omniverse_transfer_in(from: @Vault) {
            pre {
                from.isInstance(self.getType()): 
                    "Cannot deposit an incompatible token type"
            }
            post {
                self.balance == before(self.balance):
                    "balance cannot be changed in `_omniverse_transfer_in`"
            }

            let omniverseVault <- from as! @SkyWalkerFoungible.Vault;
            if omniverseVault.omniverseBalance == 0.0 {
                panic("Invalid omniverse vault");
            }
            self.omniverseBalance = self.omniverseBalance + omniverseVault.omniverseBalance;
            destroy omniverseVault;
        }

        // omniverse transfer out
        // @returns: a omniverse vault(balance: ignored, omniverseBalance > 0)
        priv fun _omniverse_transfer_out(amount: UFix64): @Vault {
            pre {
                (self.omniverseBalance > amount) && (amount > 0.0): 
                    "Not enough omniverse balance to be approved out!"
            }
            post {
                self.balance == before(self.balance):
                    "balance cannot be changed in `_omniverse_approve_out`"
            }

            self.omniverseBalance = self.omniverseBalance - amount;
            let omniverseToken <- create Vault(balance: 0.0);
            omniverseToken._set_omniverse_balance(omniverseBalance: amount);
            return <- omniverseToken;
        }

        ////////////////////////////////////////////////////////////////////
        // public part of omniverse process
        priv fun _check_and_exec(txData: AnyStruct{OmniverseProtocol.OmniverseTokenProtocol}, 
                                    signature: [UInt8], 
                                    _exec_fun: ((OmniverseFoungible): Bool) ) {
            let omniverse = txData as! OmniverseFoungible;

            // check if the input tx is for the allowed contracts
            if !SkyWalkerFoungible.checkContractAllowed(chainid: omniverse.chainid, contractName: omniverse.contractName) {
                panic("Contract Forbidden!");
            }

            // check if the operator is honest
            let opAddressOnFlow = self.owner!.address;
            OmniverseProtocol.checkValid(opAddressOnFlow: opAddressOnFlow);

            let pk = OmniverseProtocol.getPublicKey(address: opAddressOnFlow, signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1);

            // check the owner has the permission to operate the tx
            let omniOpIdentity = omniverse.getOperateIdentity();
            if String.encodeHex(omniOpIdentity) != String.encodeHex(pk.publicKey) {
                panic("Operation identities are mismatched!");
            }

            //////////////////////////////////////////////////////////////////////////
            // check input nonce
            let workingNonce = OmniverseProtocol.getWorkingNonce(pubAddr: opAddressOnFlow);
            if workingNonce == omniverse.nonce {
                if (!OmniverseProtocol.omniverseVerify(pubAddr: opAddressOnFlow, 
                                                rawData: omniverse.toBytesExceptNonce(), 
                                                signature: signature, 
                                                hashAlgorithm: HashAlgorithm.KECCAK_256)) {
                    panic("Invalid signature!");                                          
                }

                // check locked time
                let currentTime = getCurrentBlock().timestamp;
                if (currentTime - OmniverseProtocol.getLatestTxTime(pubKey: pk.publicKey)) < OmniverseProtocol.lockPeriod {
                    panic("Transaction locking has not cooled down!")
                }

                // execute operation
                if !_exec_fun(omniverse) {
                    panic("execute transaction failed!");
                }

            } else if workingNonce > omniverse.nonce {
                // This is a history transaction and check conflicts
                let publishedTx = OmniverseProtocol.OmniverseTx(txData: omniverse, signature: signature, uuid: nil);
                OmniverseProtocol.checkConflict(tx: publishedTx);
            } else {
                panic("Mismatched input nonce and working nonce!");
            }                                            
        }
        
        ////////////////////////////////////////////////////////////////////
        // omniverse approve out
        pub fun omniverseApproveOut(txData: AnyStruct{OmniverseProtocol.OmniverseTokenProtocol}, 
                                                    signature: [UInt8]) {

            let opAddressOnFlow = self.owner!.address;
            let vaultRef = &self as! & Vault;

            let execFun = fun (omniverse: OmniverseFoungible) : Bool {
                // check operation
                if omniverse.operation != 2 {
                    panic("Invalid operation. Need `2` for `omniverse approve out`. Got: ".concat(omniverse.operation.toString()))
                }

                // get the OmniverseToken out
                let localToken <- vaultRef._omniverse_approve_out(amount: omniverse.amount);
                let publishedTx = OmniverseProtocol.OmniverseTx(txData: omniverse, signature: signature, uuid: localToken.uuid);
                
                if omniverse.chainid == OmniverseProtocol.FlowChainID {
                    // the tx is promoted first on Flow
                    OmniverseProtocol.addExtractToken(recvIdentity: omniverse.recver!, token: <- localToken);
                } else {
                    // the tx is promoted first on other chains, and this is a sychronous message
                    destroy localToken;
                    //OmniverseProtocol.addExtractToken(recvIdentity: OmniverseProtocol.black_hole_pk, token: <- localToken);
                }
                // update omniverse state
                OmniverseProtocol.addOmniverseTx(pubAddr:opAddressOnFlow, omniverseTx: publishedTx);
                
                return true;
            };

            self._check_and_exec(txData: txData, 
                                    signature: signature,
                                    _exec_fun: execFun);
        }

        ////////////////////////////////////////////////////////////////////
        // omniverse transfer in
        pub fun omniverseTransferIn(txData: AnyStruct{OmniverseProtocol.OmniverseTokenProtocol}, 
                                                    signature: [UInt8]) {
            
            let opAddressOnFlow = self.owner!.address;
            let vaultRef = &self as! & Vault;

            let execFun = fun (omniverse: OmniverseFoungible) : Bool {
                // check operation
                if omniverse.operation != 0 {
                    panic("Invalid operation. Need `0` for `omniverse transfer in`. Got: ".concat(omniverse.operation.toString()))
                }

                if omniverse.chainid == OmniverseProtocol.FlowChainID {
                    // promote first on flow
                    let omniverseToken <- vaultRef._local_approve_out(amount: omniverse.amount);
                    let publishedTx = OmniverseProtocol.OmniverseTx(txData: omniverse, signature: signature, uuid: omniverseToken.uuid);
                    OmniverseProtocol.addPendingToken(recvIdentity: omniverse.recver!, token: <- omniverseToken);
                    OmniverseProtocol.addOmniverseTx(pubAddr:opAddressOnFlow, omniverseTx: publishedTx);

                } else {
                    // promote first on other chain
                    let publishedTx = OmniverseProtocol.OmniverseTx(txData: omniverse, signature: signature, uuid: nil);
                    OmniverseProtocol.addOmniverseTx(pubAddr:opAddressOnFlow, omniverseTx: publishedTx);

                }
                
                return true;
            };

            self._check_and_exec(txData: txData, 
                                    signature: signature,
                                    _exec_fun: execFun);
        }

        ////////////////////////////////////////////////////////////////////
        // omniverse transfer
        pub fun omniverseTransfer(txData: AnyStruct{OmniverseProtocol.OmniverseTokenProtocol}, signature: [UInt8]){
            let opAddressOnFlow = self.owner!.address;
            let vaultRef = &self as! & Vault;

            let execFun = fun (omniverse: OmniverseFoungible) : Bool {
                // check operation
                if omniverse.operation != 1 {
                    panic("Invalid operation. Need `1` for `transfer`. Got: ".concat(omniverse.operation.toString()))
                }

                let omniverseToken <- vaultRef._omniverse_transfer_out(amount: omniverse.amount);
                let publishedTx = OmniverseProtocol.OmniverseTx(txData: omniverse, signature: signature, uuid: omniverseToken.uuid);
                OmniverseProtocol.addPendingToken(recvIdentity: omniverse.recver!, token: <- omniverseToken);
                OmniverseProtocol.addOmniverseTx(pubAddr:opAddressOnFlow, omniverseTx: publishedTx);

                return true;
            };

            self._check_and_exec(txData: txData, 
                                    signature: signature,
                                    _exec_fun: execFun);
        }

        access(account) fun omniverseSettle(omniToken: @AnyResource{OmniverseProtocol.OmniverseToken}){
            destroy omniToken;
        }
    }

    init() {
        self.totalSupply = 0.0;
        self.contractName = self.account.address.toString().concat(".SkyWalkerFoungible");
        self.allowedContract = {};
        self.allowedContract[OmniverseProtocol.FlowChainID] = self.contractName;
    }

    pub fun checkContractAllowed(chainid: String, contractName: String): Bool {
        return self.allowedContract[chainid]! == contractName;
    }

    /// createEmptyVault allows any user to create a new Vault that has a zero balance
    ///
    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0);
    }
}
 