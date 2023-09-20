// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract SimpleHHE {
    mapping (address => bytes) pastaSKs;
    event PastaSKInstalled(address);

    address TRANSCIPHER_ADDRESS = 0x0000000000000000000000000000000001000014;

    event Log(uint);

    // function addHe(uint64[] memory op1, uint64[] memory op2) public returns (bytes memory) {        
    function addHe() public returns (uint) {        
        // emit Log(toBytes(op1));
        // emit Log(toBytes(op2));

        uint64[] memory op1 = new uint64[](2);
        op1[0]= uint64(30447);  
        op1[1] = uint64(62407);
        uint64[] memory op2 = new uint64[](2);
        op2[0] = uint64(30449);
        op2[1] = uint64(62409);
        
        emit Log(1);

        // transcipher
        bytes memory op1Bytes = callToPrec(TRANSCIPHER_ADDRESS, transcipherData(op1));
        bytes memory op2Bytes = callToPrec(TRANSCIPHER_ADDRESS, transcipherData(op2));

        emit Log(2);

        address addAddress = 0x0000000000000000000000000000000001000011;

        // add
        bytes memory encoded = encodeOps(op1Bytes, op1Bytes.length, op2Bytes, op2Bytes.length);

        emit Log(3);

        // bytes memory addResult = callToPrec(addAddress, encoded);
        // emit Log(4);

        return 1;
    }

//    function ranscipherData(bytes memory op, bytes memory pastaSK, bytes memory rk,  bytes memory bfvSK)
    function transcipherData(uint64[] memory op) internal pure returns (bytes memory) {
        bytes memory opBytes = abi.encodePacked(op);
        bytes memory opBytesLen = abi.encodePacked(opBytes.length);

        // require(op.length * 8 == opBytes.length, "length should be 8 size the original one");
        // require(opBytes.length == 16, "ok");

        // bytes memory pastaSKBytes = pastaSKs[msg.sender];
        // bytes memory pastaSKBytesLen = abi.encodePacked(pastaSKBytes.length);

    //    return bytes.concat(opBytesLen, pastaSKBytesLen, opBytes, pastaSKBytes);
        return bytes.concat(opBytesLen, opBytes);
    }

    function encodeUint64Array(uint64[] memory nums) internal pure returns(bytes memory data){
        for(uint i=0; i<nums.length; i++){
            data = abi.encodePacked(data, nums[i]);
        }
    }

    function encodeOps(bytes memory op1, uint op1Len, bytes memory op2, uint op2Len) 
        internal 
        pure
        returns (bytes memory) 
    {
        bytes memory op1Len = abi.encodePacked(op1Len);
        bytes memory op2Len = abi.encodePacked(op2Len);
        
        return bytes.concat(op1Len, op2Len, op1, op2);
    }

    // the bytes type in Solidity is stored in memory as: 1) first 32 bytes = length of the bytes value,
    // 2) then the bytes value itself. The mstore opcode stores 32 bytes, starting from a certain offset 
    // (in the bytes value to grab) to a specified location in memory. So the instruction mstore(add(b, 32), x) 
    // can be translated in plain words as "stores 32 bytes at position x in memory, starting from the 32nd bytes 
    // offset in the b" (so to skip the length, and just store b itself).
    function toBytes(uint64 x) 
        internal 
        pure
        returns (bytes memory) 
    {
        bytes memory b = new bytes(32);
        assembly { mstore(add(b, 32), x) }

        return b;
    }


    function callToPrec(address precAddress, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        // (bool ok, bytes memory result) = address(precAddress).staticcall(abi.encode(data));
        (bool ok, bytes memory result) = address(precAddress).staticcall{gas: gasleft()}(data);
        
        require(ok);

        return result;
    }

    function installPastaSK(bytes memory sk) public {
        pastaSKs[msg.sender] = sk;

        emit PastaSKInstalled(msg.sender);
    }
}


