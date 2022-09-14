pub contract OmniverseProtocol {

    pub struct interface OmniverseToken {
        pub let nonce: UInt128;
        pub let sender: [UInt8]?;
        pub let recver: [UInt8]?;
        // 0: Omniverse TransferFrom(like deposit)
        // 1: Transfer
        // 2: Omniverse Approve(like withdraw)
        pub let operation: UInt8;

        pub fun toBytesExceptNonce(): [UInt8];
        pub fun toBytes(): [UInt8];
        pub fun getOperateIdentity(): [UInt8] /*{
            pre {
                
                ((self.operation == 0) && (self.recver != nil)) || 
                ((self.operation == 1) && (self.sender != nil)) ||
                ((self.operation == 2) && (self.sender != nil)) : 
                    panic("Invalid operation! Got: ".concat(self.operation.toString()))
                
            } 
        }*/

        // @notice: Non-Fungible Token returns id, which is the `uuid` of wrapped resource `@{NonFungibleToken.INFT}`
        // @notice: Fungible Token returns nil
        pub fun getOmniID(): UInt128?;
    }

    pub struct OmniverseTx {
        // combined with `contract.address` + `contract.name`
        pub let tokenID: String;
        pub let txData: AnyStruct{OmniverseToken};
        pub let signature: [UInt8];
        pub let timestamp: UFix64;

        pub let hash: String;

        init(tokenID: String, txData: {OmniverseToken}, signature: [UInt8]) {
            self.tokenID = tokenID;
            self.txData = txData;
            self.signature = signature;
            self.timestamp = getCurrentBlock().timestamp;
             
            var rawData = self.tokenID.utf8;
            rawData = rawData.concat(self.txData.toBytes());
            rawData = rawData.concat(self.signature);

            self.hash = String.encodeHex(HashAlgorithm.KECCAK_256.hash(rawData));
        }

        pub fun txHash(): String {
            return self.hash;
        }
    }

    pub struct RecordedCertificate {
        priv var nonce: UInt128;
        pub let addressOnFlow: Address;
        // The index of array `PublishedTokenTx` is related nonce,
        // that is, the nonce of a `PublishedTokenTx` instance is its index in the array
        pub let publishedTx: [OmniverseTx];
        
        pub let evil: {UInt128: [OmniverseTx]};

        init(addressOnFlow: Address) {
            self.nonce = 0;
            self.addressOnFlow = addressOnFlow;
            self.publishedTx = [];
            self.evil = {};
        }

        pub fun validCheck() {
            if self.isMalicious() {
                panic("Account: ".concat(self.addressOnFlow.toString()).concat(" has been locked as malicious things!"));
            }
        }

        pub fun getWorkingNonce(): UInt128 {
            return self.nonce + 1;
        }

        access(contract) fun makeNextNonce() {
            self.validCheck();

            if self.nonce == UInt128.max {
                self.nonce = 0;
            } else {
                self.nonce = self.nonce + 1;
            }
        }

        access(contract) fun addTx(tx: OmniverseTx) {
            self.validCheck();

            if tx.txData.nonce != UInt128(self.publishedTx.length) {
                panic("Nonce error in transaction list! Address: ".concat(self.addressOnFlow.toString()));
            }

            self.publishedTx.append(tx);
        }

        pub fun getAllTx(): [OmniverseTx] {
            return self.publishedTx;
        }

        pub fun getLatestTx(): OmniverseTx? {
            let len = self.publishedTx.length;
            if len > 0 {
                return self.publishedTx[len - 1];
            } else if len == 0 {
                return nil;
            } else {
                panic("Invalid length");
            }
            return nil;
        }

        pub fun getLatestTime(): UFix64 {
            if let latestTx = self.getLatestTx() {
                return latestTx.timestamp;
            } else {
                return 0.0;
            }
        }

        access(contract) fun setMalicious(historyTx: OmniverseTx, currentTx: OmniverseTx) {
            if let evilRecord = (&self.evil[historyTx.txData.nonce] as &[OmniverseTx]?) {
                evilRecord.append(currentTx);
            } else {
                self.evil[historyTx.txData.nonce] = [historyTx, currentTx];
            }
        }

        pub fun getEvils(): {UInt128: [OmniverseTx]}{
            return self.evil;
        }

        pub fun isMalicious(): Bool {
            return self.evil.length > 0;
        }
    }
}
