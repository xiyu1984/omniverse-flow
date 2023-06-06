// import ERC6358NFTExample from "../contracts/ERC6358NFTExample.cdc";

// node
import ERC6358NFTExample from 0xf8d6e0586b0a20c7;

pub fun main(): {UInt32: String} {
    return ERC6358NFTExample.getAllowedMembers();
}
