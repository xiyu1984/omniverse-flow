import FungibleToken from "./utility/FungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ERC6358Protocol from "./ERC6358Protocol.cdc"
import IERC6358Token from "./IERC6358Token.cdc"
import BasicUtility from "./utility/BasicUtility.cdc";

pub contract ERC6358FungibleExample: FungibleToken, IERC6358Token {
    
    pub var totalSupply: UFix64;
    pub let flowChainID: UInt32;
    pub let contractName: String;
    
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// Vault
    ///
    /// The resource that contains the functions to send and receive tokens.
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        pub var balance: UFix64

        // The conforming type must declare an initializer
        // that allows prioviding the initial balance of the Vault
        //
        init(balance: UFix64) {
            self.balance = balance;
        }

        /// withdraw subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        pub fun withdraw(amount: UFix64): @Vault {
            panic("`withdraw` is deprecated in Omniverse Fungible Token");
        }

        /// deposit takes a Vault and adds its balance to the balance of this Vault
        ///
        pub fun deposit(from: @FungibleToken.Vault) {
            panic("`deposit` is deprecated in Omniverse Fungible Token");
        }
    }

    init() {
        self.totalSupply = 0.0;

        self.flowChainID = 7;
        self.contractName = self.account.address.toString().concat("ERC6358FungibleExample");
    }

    /// createEmptyVault allows any user to create a new Vault that has a zero balance
    ///
    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Operations of ERC6358 defination for Flow
    pub fun getTransactionCount(pk: [UInt8]): UInt128 {
        return 0;
    }

    pub fun getTransactionData(user: [UInt8], nonce: UInt128): AnyStruct{IERC6358Token.IERC6358TxData} {
        panic("to be implemented!");
    }
}
