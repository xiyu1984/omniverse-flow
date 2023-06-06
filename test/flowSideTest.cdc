import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

pub fun main(): {UInt32: String} {
    return ERC6358NFTExample.getAllowedMembers();
}
