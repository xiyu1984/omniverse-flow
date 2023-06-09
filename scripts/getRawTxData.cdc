// import IERC6358Token from "../contracts/IERC6358Token.cdc";

// node
import IERC6358Token from 0xf8d6e0586b0a20c7;

pub fun main(txData: AnyStruct{IERC6358Token.IERC6358TxProtocol}): String {
    // log(txData.toBytes());
    return String.encodeHex(txData.toBytes());
}
