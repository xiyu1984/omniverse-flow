pub contract BasicUtility {
    // UInt128, Int128, and UInt256 need to be specially processed!
    //128
    pub fun to_be_bytes_u128(_ number: UInt128): [UInt8] {
        var output = number.toBigEndianBytes();
        while output.length < 16 {
            output = [UInt8(0)].concat(output);
        }

        return output;
    }

    pub fun to_be_bytes_i128(_ number: Int128): [UInt8] {
        var output = number.toBigEndianBytes();
        while output.length < 16 {
            output = [UInt8(0)].concat(output);
        }

        return output;
    }

    // 256
    pub fun to_be_bytes_u256(_ number: UInt256): [UInt8] {
        var output = number.toBigEndianBytes();
        while output.length < 32 {
            output = [UInt8(0)].concat(output);
        }

        return output;
    }
}