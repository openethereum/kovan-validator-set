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

import "./Owned.sol";
import "./ValidatorSet.sol";

contract OuterSet is Owned, ValidatorSet {
	// System address, used by the block sealer.
	address constant SYSTEM_ADDRESS = 0xfffffffffffffffffffffffffffffffffffffffe;
	// `getValidators()` method signature.
	bytes4 constant SIGNATURE = 0xb7ab4db5;

	event FinalizeChange(address[] _new_set);

	modifier only_system_and_not_finalized() {
		require(msg.sender == SYSTEM_ADDRESS && !finalized);
		_;
	}

	modifier only_inner_and_finalized() {
		require(msg.sender == address(innerSet) && finalized);
		_;
	}

	InnerSet public innerSet;
	// Was the last validator change finalized.
	bool public finalized;

	function setInner(address _inner) public only_owner {
		innerSet = InnerSet(_inner);
	}

	// For innerSet.
	function initiateChange(bytes32 _parent_hash, address[] _new_set) public only_inner_and_finalized {
		finalized = false;
		InitiateChange(_parent_hash, _new_set);
	}

	// For sealer.
	function finalizeChange() public only_system_and_not_finalized {
		finalized = true;
		innerSet.finalizeChange();
		FinalizeChange(getValidators());
	}

	function getValidators() public constant returns (address[]) {
		address addr = innerSet;
		bytes4 sig = SIGNATURE;
		assembly {
			mstore(0, sig)
			let ret := call(0xfffffffface8, addr, 0, 0, 4, 0, 0)
			jumpi(0x02,iszero(ret))
			returndatacopy(0, 0, returndatasize)
			return(0, returndatasize)
		}
	}

	function reportBenign(address validator, uint256 blockNumber) public {
		innerSet.reportBenign(validator, blockNumber);
	}
	function reportMalicious(address validator, uint256 blockNumber, bytes proof) public {
		innerSet.reportMalicious(validator, blockNumber, proof);
	}
}

contract InnerSet {
	OuterSet public outerSet;

	modifier only_outer() {
		require(msg.sender == address(outerSet));
		_;
	}

	function getValidators() public constant returns (address[]);
	function finalizeChange() public;
	function reportBenign(address validator, uint256 blockNumber) public;
	function reportMalicious(address validator, uint256 blockNumber, bytes proof) public;
}
