pragma solidity ^0.4.15;

library AddressVotes {
	// Tracks the number of votes from different addresses.
	struct Data {
		uint count;
		// Keeps track of who voted, prevents double vote.
		mapping(address => bool) inserted;
	}

	// Total number of votes cast.
	function count(Data storage self) public constant returns (uint) {
		return self.count;
	}

	// Did the voter already vote.
	function contains(Data storage self, address voter) public constant returns (bool) {
		return self.inserted[voter];
	}

	// Voter casts a vote.
	function insert(Data storage self, address voter) public returns (bool) {
		if (self.inserted[voter]) { return false; }
		self.count++;
		self.inserted[voter] = true;
		return true;
	}

	// Retract a vote by a voter.
	function remove(Data storage self, address voter) public returns (bool) {
		if (!self.inserted[voter]) { return false; }
		self.count--;
		self.inserted[voter] = false;
		return true;
	}
}
