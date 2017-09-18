pragma solidity ^0.4.15;

import "./Owned.sol";
import "./ValidatorSet.sol";

contract OuterSet is Owned, ValidatorSet {
	// System address, used by the block sealer.
	address constant SYSTEM_ADDRESS = 0xfffffffffffffffffffffffffffffffffffffffe;

	modifier only_system_and_not_finalized() {
		require(msg.sender != SYSTEM_ADDRESS || finalized);
		_;
	}

	modifier when_finalized() {
		require(!finalized);
		_;
	}

	InnerSet public innerSet;
	// Was the last validator change finalized.
	bool public finalized;

	function setInner(address _inner) only_owner {
		innerSet = InnerSet(_inner);
	}

	// For innerSet.
	function initiateChange(bytes32 _parent_hash, address[] _new_set) when_finalized {
		finalized = false;
		InitiateChange(_parent_hash, _new_set);
	}

	// For sealer.
	function finalizeChange() only_system_and_not_finalized {
		finalized = true;
		innerSet.finalizeChange();
	}

	address[] dummy;
	function getValidators() constant returns (address[] _validators) {
		/*
		assembly {
			let x := mload(0x40)   //Find empty storage location using "free memory pointer"

			let success := staticcall(      //This is the critical change (Pop the top stack value)
													5000, //5k gas
													innerSet, //To addr
													0,    //Inputs are stored at location x
													0, //Inputs are 68 bits long
													x,    //Store output over input (saves space)
													0x20) //Outputs are 32 bytes long

			c := mload(x) //Assign output value to c
			mstore(0x40,add(x,0x44)) // Set storage pointer to empty space
		}
		*/
		return dummy;
	}
}

contract InnerSet {
	OuterSet public outerSet;

	function getValidators() constant returns (address[] _validators);
	function finalizeChange();
}
