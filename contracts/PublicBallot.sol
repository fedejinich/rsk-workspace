// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

// todo(fedejinich) add feature to show the vote only to the owner

contract PublicBallot {
    bool open = true;
    string public cause;
    mapping(address => Proposal) private proposals;
    address[] private proposalsAux;
    // votes are encrytped with PASTA cipher
    mapping(address => Vote) private votes;
    address[] private votesAux;

    // structs
    struct Proposal {
        string proposal;
        bool exists;
    }

    struct Vote {
        uint64[] vote;
        bool exists;
    }

    // events
    event NewProposal(address, string);
    event Winner(string, uint256);
    event VoteCount(uint64[]);
    event NewVote(address);
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

    function vote(uint64[] calldata vot) public {
        require(!votes[msg.sender].exists, "Address already voted");

        Vote memory v = Vote(vot, true);
        votes[msg.sender] = v;
        votesAux.push(msg.sender);

        emit NewVote(msg.sender);
    }

    // todo(fedejinich) restric this to only owner
    function voteCount() public view returns (uint64[] memory) {
        require(open == false, "ballot still open");

        // transcipher from PASTA to BFV (accumulate over the first vote)
        uint64[] memory result = new uint64[](4);
        for (uint256 i = 1; i < votesAux.length; i++) {
            address addr = votesAux[i];
            uint64[] memory v = votes[addr].vote;

            // count encytrpted votes
            result = add(result, v);
        }

        // the result is an array of the total amount of
        // votes indexed by proposal
        //  P1 P2 P3 P4
        // [ 1, 4, 6, 2 ]
        return result;
    }

    function closeBallot() public {
        require(open == true, "ballot is already closed");
        open = false;

        emit ClosedBallot();
    }

    function winner() public {
        require(proposalsAux.length > 0, "there isn't any proposal");

        uint64[] memory vc = voteCount();
        uint64[] memory results = vc;

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

    function add(uint64[] memory op1, uint64[] memory op2)
        internal
        pure 
        returns (uint64[] memory)
    {
        require(op1.length == op2.length, "different lengths");
        for (uint256 i = 0; i < op1.length; i++) {
            op1[i] = op1[i] + op2[i];
        }

        return op1;
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
