
# Generate accounts for emulator
## Generate Alice
flow accounts create --key 417b9ae42da624e4bc680f0231795d62aa28229f54684e7e637d73157f58266558b8ae5aaa47ea087767606962a10874de1dc737bfb096b4e05328c175beddfc --sig-algo ECDSA_secp256k1
### transfer Flow Token
flow transactions send ./transactions/transferFlow.cdc 100.0 0x01cf0e2f2f715450

## Generate Bob
flow accounts create --key 11fbbd1eb335fedb94c342d9ed4638570b177c67014a439716162bc22f8de8224bbdd5aa599bf0b3de1559df68834dce9f7eb1bfc5a177d0792bbf2f3e46524f --sig-algo ECDSA_secp256k1
### transfer Flow Token
flow transactions send ./transactions/transferFlow.cdc 100.0 0x179b6b1cb6755e31

## Generate Carl
flow accounts create --key 20409b2afd00ef0dcbbe8111bc56fbcdee742e26d9981c20ae1a4f10668bde66b4ee64edf92727b37a6c0d2ea8c2c090e0cc9f1b357b67694cfb918afd7b6b55 --sig-algo ECDSA_secp256k1
### transfer Flow Token
flow transactions send ./transactions/transferFlow.cdc 100.0 0xf3fcd2c1a78f5eee

# Deploy
flow project deploy --update

# active accounts
flow transactions send ./transactions/activeSimuAddress.cdc 0xf8d6e0586b0a20c7
flow transactions send ./transactions/activeSimuAddress.cdc 0x01cf0e2f2f715450
flow transactions send ./transactions/activeSimuAddress.cdc 0x179b6b1cb6755e31
flow transactions send ./transactions/activeSimuAddress.cdc 0xf3fcd2c1a78f5eee

# create collection
flow transactions send ./transactions/createCollection.cdc --signer emulator-account
flow transactions send ./transactions/createCollection.cdc --signer emulator-Alice
flow transactions send ./transactions/createCollection.cdc --signer emulator-Bob
flow transactions send ./transactions/createCollection.cdc --signer emulator-Carl

# set member and set lock period (for test)
cd ./off-chain
node ./simulator.mjs --set-lock-period 30.0
cd ..
