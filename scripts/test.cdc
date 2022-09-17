import ExampleToken from "../contracts/ExampleToken.cdc"

pub fun main() {
    let pubAcct = getAccount(0xf8d6e0586b0a20c7);
    log(pubAcct.contracts.get(name: "ExampleToken")!.address);
    log(pubAcct.contracts.get(name: "ExampleToken")!.name);

    log(UInt128(1).toBigEndianBytes());
    log(pubAcct.address.toString());
}
