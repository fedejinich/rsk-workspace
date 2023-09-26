// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

// todo(fedejinich) add feature to show the vote only to the owner

contract PrivateBallot {
    bool open = true;
    string public cause;
    mapping(address => Proposal) private proposals;
    address[] private proposalsAux;
    // votes are encrytped with PASTA cipher
    mapping(address => EncryptedVote) private votes;
    address[] private votesAux;

    // structs
    struct Proposal {
        string proposal;
        bool exists;
    }

    struct EncryptedVote {
        uint64[] vote;
        bool exists;
    }

    // events
    event NewProposal(address, string);
    event NewEncryptedVote(address);
    event Winner(string, uint256);
    event VoteCount(uint64[]);
    event Vote(bytes);
    event ClosedBallot();

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

        EncryptedVote memory v = EncryptedVote(encryptedVote, true);
        votes[msg.sender] = v;
        votesAux.push(msg.sender);

        emit NewEncryptedVote(msg.sender);
    }

    // todo(fedejinich) restric this to only owner
    function voteCount() public view returns (bytes memory) {
        require(open == false, "ballot still open");

        // transcipher from PASTA to BFV (accumulate over the first vote)
        uint64[] memory encryptedVote = votes[votesAux[0]].vote;
        bytes memory encryptedResult = callToPrec(
            TRANS_ADDR,
            transcipherData(encryptedVote)
        );

        if (votesAux.length == 1) {
            return callToPrec(DECRYPT_ADDR, encryptedResult);
        }

        for (uint256 i = 1; i < votesAux.length; i++) {
            address addr = votesAux[i];
            uint64[] memory encryptedVote = votes[addr].vote;

            // transcipher from PASTA to BFV
            bytes memory encryptedVoteBfv = callToPrec(
                TRANS_ADDR,
                transcipherData(encryptedVote)
            );

            // count encytrpted votes
            encryptedResult = add(encryptedResult, encryptedVoteBfv);
        }

        // the result is an array of the total amount of
        // votes indexed by proposal
        //  P1 P2 P3 P4
        // [ 1, 4, 6, 2 ]
        return encryptedResult;
    }

    function closeBallot() public {
        require(open == true, "ballot is already closed");
        open = false;
        
        emit ClosedBallot();
    }

    function winner() public returns (uint256[] memory) {
        require(proposalsAux.length > 0, "there isn't any proposal");

        bytes memory vc = voteCount();
        bytes memory dec = callToPrec(DECRYPT_ADDR, vc);
        uint64[] memory results = bytesToUint64Array(dec);

        // gets index and the amount of votes
        uint256 index = 0;
        uint256 maxValue = 0; // amount of votes
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i] > maxValue) {
                maxValue = results[i];
                index = uint256(i);
            }
        }

        address addr = proposalsAux[index];

        emit Winner(proposals[addr].proposal, maxValue);
    }

    function add(bytes memory op1, bytes memory op2)
        internal
        view
        returns (bytes memory)
    {
        bytes memory data = bytes.concat(op1, op2);

        return callToPrec(ADD_ADDR, data);
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

    function callToPrec(address precAddress, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        (bool ok, bytes memory result) = address(precAddress).staticcall{
            gas: 1
        }(data);

        // todo(fedejinich) this sholuldn't be commented
        //require(ok, "prec failed");

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
}
