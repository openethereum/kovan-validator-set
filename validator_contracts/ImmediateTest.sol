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

// Basic contract used for testing a validator set with immediate transitions.
contract ImmediateTest is ImmediateSet {
	// Accounts used for testing: "0".sha3() and "1".sha3()
	address[] public validators = [0x7d577a597b2742b498cb5cf0c26cdcd726d39e6e, 0x82a978b3f5962a5b0957d9ee9eef472ee55b42f1];
	mapping(address => uint) indices;
	address public disliked;

	function ImmediateTest() public {
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
		validators.push(_validator);
		indices[_validator] = validators.length - 1;
	}

	// Remove a validator from the list.
	function reportMalicious(address _validator, uint, bytes) public {
		validators[indices[_validator]] = validators[validators.length-1];
		delete indices[_validator];
		delete validators[validators.length-1];
		validators.length--;
	}

	function reportBenign(address _validator, uint _blockNumber) public {
		disliked = _validator;
	}
}
