// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract PrivateBallot {
    // fields
    string public cause;
    mapping(address => Proposal) private proposals;
    address[] private proposalsAux;

    mapping(address => PrivateVote) private votes;
    address[] private votesAux;

    // structs
    struct Proposal {
        string proposal;
        bool exists;
    }

    struct PrivateVote {
        uint64[] vote;
        bool exists;
    }

    struct RealVote {
        string proposal;
    }

    // events
    event NewProposal(address, string);
    event NewVote(address);
    event Winner(string, uint256);
    event VoteCount(uint64[]);
    event Dec(bytes);

    // consts
    address ADD_ADDR = 0x0000000000000000000000000000000001000011;
    address TRANS_ADDR = 0x0000000000000000000000000000000001000014;
    address DECRYPT_ADDR = 0x0000000000000000000000000000000001000016;

    function addProposal(string memory p) public {
        Proposal memory prop = Proposal(p, true);
        proposals[msg.sender] = prop;
        proposalsAux.push(msg.sender);

        require(proposalsAux.length > 0);

        emit NewProposal(msg.sender, prop.proposal);
    }

    function vote(uint64[] calldata encryptedVote) public {
        require(!votes[msg.sender].exists, "Address already voted");

        //bytes memory voteBfv = callToPrec(
        //    TRANS_ADDR,
        //    transcipherData(encryptedVote)
        //);

        PrivateVote memory v = PrivateVote(encryptedVote, true);
        votes[msg.sender] = v;
        votesAux.push(msg.sender);

        emit NewVote(msg.sender);
    }

    function voteCount()
        public
        view
        returns (
            bytes memory /*onlyOwner*/
        )
    //uint64[] memory
    {
        require(votesAux.length != 0, "no votes"); // todo(fedejinich) remove this

        // transcipher from PASTA to BFV (accumulate over the first vote)
        uint64[] memory vp = votes[votesAux[0]].vote;
        bytes memory encryptedResult = callToPrec(
            TRANS_ADDR,
            transcipherData(vp)
        );

        if (votesAux.length == 1) {
            // the result is an array of the total amount of
            // votes indexed by proposal
            //  P1 P2 P3 P4
            // [ 1, 4, 6, 2 ]
            bytes memory r = decrypt(encryptedResult);

            return r;
        }

        for (uint256 i = 1; i < votesAux.length; i++) {
            address addr = votesAux[i];
            uint64[] memory votePasta = votes[addr].vote;

            // transcipher from PASTA to BFV
            bytes memory voteBfv = callToPrec(
                TRANS_ADDR,
                transcipherData(votePasta)
            );

            // count encytrpted votes
            encryptedResult = add(encryptedResult, voteBfv);
        }

        // the result is an array of the total amount of
        // votes indexed by proposal
        //  P1 P2 P3 P4
        // [ 1, 4, 6, 2 ]
        return encryptedResult;
    }

    function reverse(uint64[] memory original)
        public
        pure
        returns (uint64[] memory)
    {
        uint64[] memory reversed = new uint64[](original.length);

        for (uint256 i = 0; i < original.length; i++) {
            reversed[i] = original[original.length - 1 - i];
        }

        return reversed;
    }

    //function winner() external returns (uint256) {
    function winner() public view returns (uint256[] memory) {
        require(proposalsAux.length > 0, "there isn't any proposal");

        bytes memory vc = voteCount();
        bytes memory dec = callToPrec(DECRYPT_ADDR, vc);
        uint64[] memory results = bytesToUint64Array(dec);

        
        uint256 index = 0;
        uint256 maxValue = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i] > maxValue) {
                maxValue = results[i];
                index = uint256(i);
            }
        }

        address addr = proposalsAux[index];

        uint256[] memory foo = new uint256[](2);
        foo[0] = index;
        foo[1] = maxValue;

        //emit Winner(proposals[addr].proposal, maxValue);
        
        return foo;
    }

    function add(bytes memory op1, bytes memory op2)
        internal
        view
        returns (bytes memory)
    {
        /*
        bytes memory op1Len = abi.encodePacked(op1.length);
        bytes memory op2Len = abi.encodePacked(op2.length);
        bytes memory data = bytes.concat(op1Len, op2Len, op1, op2);
        */

        bytes memory data = bytes.concat(op1, op2);

        return callToPrec(ADD_ADDR, data);
    }

    function bytesToUint64Array2(bytes memory data)
        public
        pure
        returns (uint64[] memory)
    {
        // Ensure that the input bytes length is a multiple of 8
        require(data.length % 8 == 0, "bytes length must be a multiple of 8");

        uint64[] memory results = new uint64[](data.length / 8);

        for (uint256 i = 0; i < data.length / 8; i++) {
            uint64 value;

            assembly {
                // Load 8 bytes from the data into the value
                value := mload(add(data, add(0x20, mul(i, 8))))
            }

            results[i] = value;
        }

        return results;
    }

    function decrypt(bytes memory e) public view returns (bytes memory) {
        //function decrypt(bytes memory e) public view returns (uint64[] memory) {
        bytes memory dec = callToPrec(DECRYPT_ADDR, e);
        return dec;

        //return bytesToUint64Array(dec);
    }

    function bytesToUint64Array(bytes memory b)
        internal
        pure
        returns (uint64[] memory)
    {
        require(b.length % 8 == 0, "should be multiple of 8");

        uint256 size = b.length / 8;
        uint64[] memory result = new uint64[](size);

        uint256 j = 0;
        for (uint256 i = 0; i < b.length; i = i + 8) {
            uint64 r = toUint64(b, i);
            result[j] = r;
            j++;
        }

        return reverse(result);
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    /*
    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
    */

    function callToPrec(address precAddress, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        (bool ok, bytes memory result) = address(precAddress).staticcall{
            gas: 1
        }(data);

        require(ok);

        return result;
    }

    function transcipherData(uint64[] memory op)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory opBytes = abi.encodePacked(op);
        bytes memory opBytesLen = abi.encodePacked(opBytes.length);

        // require(op.length * 8 == opBytes.length, "length should be 8 size the original one");
        // require(opBytes.length == 16, "ok");

        // bytes memory pastaSKBytes = pastaSKs[msg.sender];
        // bytes memory pastaSKBytesLen = abi.encodePacked(pastaSKBytes.length);

        //    return bytes.concat(opBytesLen, pastaSKBytesLen, opBytes, pastaSKBytes);
        return bytes.concat(opBytesLen, opBytes);
    }

    /*
    // shows the real vote if it's the same address
    function showRealVote(address addr) public returns (RealVote memory) {
        require(msg.sender == addr, "Cannot show vote of another address");
        PrivateVote memory v = votes[msg.sender];

        return realVote(decrypt(v.vote)); // todo(fedejinich) too much stuff :(
    }
    
    function realVote(uint[] memory v) public returns (RealVote memory) {
        RealVote memory rv;
        return rv;
    }
    */
}
