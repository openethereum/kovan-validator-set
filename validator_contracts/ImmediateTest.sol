pragma solidity ^0.4.6;

import "./ValidatorSet.sol";

// Basic contract used for testing a validator set with immediate transitions.
contract ImmediateTest is ImmediateSet {
	// Accounts used for testing: "0".sha3() and "1".sha3()
	address[] public validators = [0x7d577a597b2742b498cb5cf0c26cdcd726d39e6e, 0x82a978b3f5962a5b0957d9ee9eef472ee55b42f1];
	mapping(address => uint) indices;
	address public disliked;

	function TestList() {
		for (uint i = 0; i < validators.length; i++) {
			indices[validators[i]] = i;
		}
	}

	// Called on every block to update node validator list.
	function getValidators() constant returns (address[]) {
		return validators;
	}

	// Expand the list of validators.
	function addValidator(address _validator) {
		validators.push(_validator);
		indices[_validator] = validators.length - 1;
	}

	// Remove a validator from the list.
	function reportMalicious(address _validator, uint _blockNumber, bytes _proof) {
		validators[indices[_validator]] = validators[validators.length-1];
		delete indices[_validator];
		delete validators[validators.length-1];
		validators.length--;
	}

	function reportBenign(address _validator, uint _blockNumber) {
		disliked = _validator;
	}
}
