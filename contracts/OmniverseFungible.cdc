import OmniverseProtocol from "./OmniverseProtocol.cdc";

pub contract OmniverseFungible {
    pub struct OmniverseFT: OmniverseProtocol.OmniverseToken {
        pub let nonce: UInt128;
        // resource uuid, which is the unique id for resources on Flow
        pub let amount: UFix64;
        // Flow is special, 
        // and remember to put the omniverse address in the position of first public key as the Omniverse address
        // Note that `SignatureAlgorithm.ECDSA_secp256k1` is neccessary
        pub let sender: [UInt8]?;
        pub let recver: [UInt8]?;
        // 0: Omniverse TransferFrom(like deposit)
        // 1: Transfer
        // 2: Omniverse Approve(like withdraw)
        pub let operation: UInt8;

        init(nonce: UInt128, amount: UFix64, sender: [UInt8]?, recver: [UInt8]?, operation: UInt8) {
            self.nonce = nonce;
            self.amount = amount;
            self.sender = sender;
            self.recver = recver;
            self.operation = operation;
        }

        pub fun toBytesExceptNonce(): [UInt8] {
            var output: [UInt8] = [];
            
            output = output.concat(self.amount.toBigEndianBytes());

            if let sender = self.sender {
                output = output.concat(sender);
            }
            if let recver = self.recver {
                output = output.concat(recver);
            }

            output.append(self.operation);
            
            return output;
        }

        pub fun toBytes(): [UInt8] {
            var output: [UInt8] = [];
            
            output = output.concat(self.nonce.toBigEndianBytes());
            output = output.concat(self.amount.toBigEndianBytes());

            if let sender = self.sender {
                output = output.concat(sender);
            }
            if let recver = self.recver {
                output = output.concat(recver);
            }

            output.append(self.operation);
            
            return output;
        }

        pub fun getOperateIdentity(): [UInt8] {
            switch self.operation {
                case UInt8(0):
                    return self.recver!;
                case UInt8(1):
                    return self.sender!;
                case UInt8(2):
                    return self.sender!;
            }

            panic("Invalid operation! Got: ".concat(self.operation.toString()));
        }

        pub fun getOmniID(): UInt128? {
            return nil;
        }
    }
}
