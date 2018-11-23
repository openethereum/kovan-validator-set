// Copyright 2017 Peter Czaban, Parity Technologies Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.5;


interface ValidatorSet {
	/// Issue this log event to signal a desired change in validator set.
	/// This will not lead to a change in active validator set until
	/// finalizeChange is called.
	///
	/// Only the last log event of any block can take effect.
	/// If a signal is issued while another is being finalized it may never
	/// take effect.
	///
	/// _parentHash here should be the parent block hash, or the
	/// signal will not be recognized.
	event InitiateChange(bytes32 indexed _parentHash, address[] _newSet);

	/// Called when an initiated change reaches finality and is activated.
	/// Only valid when msg.sender == SYSTEM (EIP96, 2**160 - 2).
	///
	/// Also called when the contract is first enabled for consensus. In this case,
	/// the "change" finalized is the activation of the initial set.
	function finalizeChange()
		external;

	/// Reports benign misbehavior of validator of the current validator set
	/// (e.g. validator offline).
	function reportBenign(address validator, uint256 blockNumber)
		external;

	/// Reports malicious misbehavior of validator of the current validator set
	/// and provides proof of that misbehavor, which varies by engine
	/// (e.g. double vote).
	function reportMalicious(address mvalidator, uint256 blockNumber, bytes calldata proof) external;

	/// Get current validator set (last enacted or initial if no changes ever made).
	function getValidators()
		external
		view
		returns (address[] memory);
}
