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

pragma solidity ^0.4.6;

import "./interfaces/ValidatorSet.sol";

// Basic contract used for testing the validator set.
contract Test is ValidatorSet {
	// Current active set of validators. Accounts used for testing: "0".sha3() and "1".sha3()
	address[] public validators = [0x7d577a597b2742b498cb5cf0c26cdcd726d39e6e, 0x82a978b3f5962a5b0957d9ee9eef472ee55b42f1];
	// Real time set of validators.
	address[] public pending = validators;
	// Indices of validators in the pending set.
	mapping(address => uint) indices;
	// Validator that has been recently reported as benign misbehaving.
	address public disliked;

	function TestList() public {
		for (uint i = 0; i < validators.length; i++) {
			indices[validators[i]] = i;
		}
	}

	// Called on every block to update node validator list.
	function getValidators() public constant returns (address[]) {
		return validators;
	}

	// Expand the list of validators.
	function addValidator(address _validator) public {
		pending.push(_validator);
		indices[_validator] = validators.length - 1;
		InitiateChange(block.blockhash(block.number - 1), pending);
	}

	// Remove a validator from the list.
	function reportMalicious(address _validator) public {
		pending[indices[_validator]] = pending[pending.length-1];
		delete indices[_validator];
		delete pending[pending.length-1];
		pending.length--;
		InitiateChange(block.blockhash(block.number - 1), pending);
	}

	function reportBenign(address _validator) public {
		disliked = _validator;
	}

	function finalizeChange() public {
		validators = pending;
	}
}
