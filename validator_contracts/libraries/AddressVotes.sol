//! Copyright 2017 Peter Czaban, Parity Technologies Ltd.
//!
//! Licensed under the Apache License, Version 2.0 (the "License");
//! you may not use this file except in compliance with the License.
//! You may obtain a copy of the License at
//!
//!     http://www.apache.org/licenses/LICENSE-2.0
//!
//! Unless required by applicable law or agreed to in writing, software
//! distributed under the License is distributed on an "AS IS" BASIS,
//! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//! See the License for the specific language governing permissions and
//! limitations under the License.

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
