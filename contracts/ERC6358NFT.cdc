import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"

pub contract ERC6358NFT: NonFungibleToken {
    /// The total number of tokens of this type in existence
    pub var totalSupply: UInt64

    /// Event that emitted when the NFT contract is initialized
    pub event ContractInitialized()

    /// Event that is emitted when a token is withdrawn,
    pub event Withdraw(id: UInt64, from: Address?)

    /// Event that emitted when a token is deposited to a collection.
    pub event Deposit(id: UInt64, to: Address?)

    
}
