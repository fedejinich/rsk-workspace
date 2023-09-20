// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract PrivateBallot {
    // fields
    string public cause;
    mapping(address => Proposal) private proposals;
    address[] proposalsAux;

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

    // consts
    address ADD_ADDR = 0x0000000000000000000000000000000001000011;
    address TRANS_ADDR = 0x0000000000000000000000000000000001000014;
    address DECRYPT_ADDR = 0x0000000000000000000000000000000001000016;

    function addProposal(string memory p) public {
        Proposal memory prop = Proposal(p, true);
        proposals[msg.sender] = prop;

        emit NewProposal(msg.sender, prop.proposal);
    }

    function vote(uint64[] calldata encryptedVote) public {
        //require(!votes[msg.sender].exists, "Address already voted");

        PrivateVote memory v = PrivateVote(encryptedVote, true);
        votes[msg.sender] = v;

        emit NewVote(msg.sender);
    }

    function voteCount()
        public 
        returns (
            /*onlyOwner*/
            uint64[] memory
        )
    {
        bytes memory encryptedResult;
        for (uint256 i = 0; i < votesAux.length; i++) {
            address addr = votesAux[i];
            uint64[] memory votePasta = votes[addr].vote;

            // transcipher from PASTA to BFV
            bytes memory voteBfv = callToPrec(TRANS_ADDR,
                                              transcipherData(votePasta));

            // count encytrpted votes
            encryptedResult = add(encryptedResult, voteBfv);
        }

        // the result is an array of the total amount of
        // votes indexed by proposal
        //  P1 P2 P3 P4
        // [ 1, 4, 6, 2 ]
        uint64[] memory result = decrypt(encryptedResult);

        emit VoteCount(result);

        return result;
    }

    function winner() external returns (uint256) {
        require(proposalsAux.length > 0, "there isn't any proposal");
        uint64[] memory results = voteCount();

        uint256 index = 0;
        uint256 maxValue = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i] > maxValue) {
                maxValue = results[i];
                index = uint256(i);
            }
        }

        address addr = proposalsAux[index];

        emit Winner(proposals[addr].proposal, maxValue);

        return maxValue; // todo(fedejinich) it can be the proposal string
    }

    function add(bytes memory op1, bytes memory op2)
        internal
        view
        returns (bytes memory)
    {
        bytes memory op1Len = abi.encodePacked(op1.length);
        bytes memory op2Len = abi.encodePacked(op2.length);
        bytes memory data = bytes.concat(op1Len, op2Len, op1, op2);

        return callToPrec(ADD_ADDR, data);
    }

    function decrypt(bytes memory e) 
        public
        view
        returns (uint64[] memory)
    {
        bytes memory dec = callToPrec(DECRYPT_ADDR, e);

        return bytesToUint64Array(dec);
    }

    /*
    function bytesToUintArray(bytes memory b) 
        internal
        pure
        returns (uint[] memory)
    {
        // bytes to uint[]
        uint[] memory result;
        uint j = 0;
        for (uint i = 0; i < b.length; i = i + 32) {
            uint r = toUint256(b, i);
            result[j] = r;
            j++;
        }

        return result;
    }
    */

    function bytesToUint64Array(bytes memory b) 
        internal
        pure
        returns (uint64[] memory)
    {
        // bytes to uint[]
        uint64[] memory result;
        uint j = 0;
        for (uint i = 0; i < b.length; i = i + 32) {
            uint64 r = toUint64(b, i);
            result[j] = r;
            j++;
        }

        return result;
    }

    function toUint64(bytes memory _bytes, uint _start)
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
            gas: 50000
        }(data);

        require(ok);

        return result;
    }

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
