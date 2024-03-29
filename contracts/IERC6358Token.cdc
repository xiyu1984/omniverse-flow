/**
*   According to the standard at https://eips.ethereum.org/EIPS/eip-6358
*/ 

pub contract interface IERC6358Token {
    
    pub let flowChainID: UInt32;
    pub let contractName: String;

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Interfaces of ERC6358 defination for Flow
    pub resource interface IERC6358Operation {
        pub fun sendOmniverseTransaction(otx: AnyStruct{IERC6358TxProtocol});
        // pub fun getTransactionCount(pk: [UInt8]): UInt128;
        // pub fun getTransactionData(user: [UInt8], nonce: UInt128): OmniverseTxData;

        // Not in the `EIP-6358` standard, but necessary in Flow
        access(account) fun omniverseExec(omniToken: @AnyResource{IERC6358TokenExec});
    }

    pub resource interface IERC6358TokenExec {
        access(account) var lockedTime: UFix64;

        access(account) fun setLockedTime() {
            post {
                self.lockedTime == getCurrentBlock().timestamp: 
                    panic("set locked time error!");
            }
        }

        pub fun getLockedTime(): UFix64;
    }

    pub struct interface IERC6358Payload {
        // 0: Omniverse Transfer
        // 1: Omniverse mint
        // 2: Omniverse burn
        pub let operation: UInt8;
        pub let exData: [UInt8];

        pub fun toBytes(): [UInt8];
    }

    pub struct interface IERC6358TxProtocol {
        pub let nonce: UInt128;

        // The chain where the o-transaction is initiated
        pub let chainid: UInt32;
        // The contract address from which the o-transaction is first initiated
        // on Flow, this is concat by `account address`+``
        pub let initiateSC: String;
        // The Omniverse account which signs the o-transaction
        pub let from: [UInt8];

        pub let payload: AnyStruct{IERC6358Payload};

        pub let signature: [UInt8];

        // pub fun toBytesExceptNonce(): [UInt8];
        pub fun toBytes(): [UInt8];
        // pub fun getOperateIdentity(): [UInt8];
    }

    pub struct interface IERC6358TxData {
        pub let txData: AnyStruct{IERC6358TxProtocol};
        pub let _time: UFix64;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Operations of ERC6358 defination for Flow
    pub fun getTransactionCount(pk: [UInt8]): UInt128;
    pub fun getTransactionData(user: [UInt8], nonce: UInt128): AnyStruct{IERC6358TxData};
}
