# Deploy
flow project deploy --update


# Generate accounts for emulator
## Generate Alice
flow accounts create --key 81262aa27f1630ccf1293300e8e1d9a6ba542dffa796b860d53873867175e9d31bd7b7581d2f200f9c3dfdbc10ae912ff036946981e3d8996a14f186d20e3e2f
### transfer Flow Token
flow transactions send ./transactions/transferFlow.cdc 100.0 0x01cf0e2f2f715450

## Generate Bob
flow accounts create --key 7bfb71eeda6d501caa816044b3382cec7d57e423baee3e02bb47a4420c149fbde0c43ff947eedbdc8740a29f66c7a04add27fe6db1e2976e50e1b2abf302da42
### transfer Flow Token
flow transactions send ./transactions/transferFlow.cdc 100.0 0x179b6b1cb6755e31

# SQoS (optional)
## set sqos
### Optimistic
# flow transactions send ./transactions/SQoS/setOptimistic.cdc 

## get sqos
# flow scripts execute ./scripts/SQoS/getSQoS.cdc 0xf8d6e0586b0a20c7
