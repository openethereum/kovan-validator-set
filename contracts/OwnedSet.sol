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

pragma solidity ^0.4.22;

import "./Owned.sol";
import "./ValidatorSet.sol";


// Owner can add or remove validators.
contract OwnedSet is Owned, ValidatorSet {
	// TYPES
	struct AddressStatus {
		bool isIn;
		uint index;
	}

	// EVENTS
	event Report(address indexed reporter, address indexed reported, bool indexed malicious);
	event ChangeFinalized(address[] currentSet);

	// STATE

	// System address, used by the block sealer.
	address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
	uint public recentBlocks = 20;

	// Current list of addresses entitled to participate in the consensus.
	address[] validators;
	address[] pending;
	mapping(address => AddressStatus) status;

	// Was the last validator change finalized. Implies validators == pending
	bool public finalized;

	// MODIFIERS
	modifier onlySystemAndNotFinalized() {
		require(msg.sender == SYSTEM_ADDRESS && !finalized);
		_;
	}

	modifier whenFinalized() {
		require(finalized);
		_;
	}

	modifier isValidator(address _someone) {
		bool isIn = status[_someone].isIn;
		uint index = status[_someone].index;

		require(isIn && index < validators.length && validators[index] == _someone);
		_;
	}

	modifier isNotValidator(address _someone) {
		require(!status[_someone].isIn);
		_;
	}

	modifier isRecent(uint _blockNumber) {
		require(block.number <= _blockNumber + recentBlocks && _blockNumber < block.number);
		_;
	}

	constructor(address[] _initial)
		public
	{
		pending = _initial;
		for (uint i = 0; i < _initial.length; i++) {
			status[_initial[i]].isIn = true;
			status[_initial[i]].index = i;
		}
		validators = pending;
	}

	// Called when an initiated change reaches finality and is activated.
	function finalizeChange()
		external
		onlySystemAndNotFinalized
	{
		finalizeChangeInternal();
	}

	// OWNER FUNCTIONS

	// Add a validator.
	function addValidator(address _validator)
		external
		onlyOwner
		isNotValidator(_validator)
	{
		status[_validator].isIn = true;
		status[_validator].index = pending.length;
		pending.push(_validator);
		initiateChange();
	}

	// Remove a validator.
	function removeValidator(address _validator)
		external
		onlyOwner
		isValidator(_validator)
	{
		// Remove validator from pending by moving the
		// last element to its slot
		uint index = status[_validator].index;
		pending[index] = pending[pending.length - 1];
		status[pending[index]].index = index;
		delete pending[pending.length - 1];
		pending.length--;

		// Reset address status
		delete status[_validator].index;
		status[_validator].isIn = false;

		initiateChange();
	}

	function setRecentBlocks(uint _recentBlocks)
		external
		onlyOwner
	{
		recentBlocks = _recentBlocks;
	}

	// MISBEHAVIOUR HANDLING

	// Report that a validator has misbehaved maliciously.
	function reportMalicious(address _validator, uint _blockNumber, bytes _proof)
		external
		isValidator(msg.sender)
		isValidator(_validator)
		isRecent(_blockNumber)
	{
		emit Report(msg.sender, _validator, true);
	}

	// Report that a validator has misbehaved in a benign way.
	function reportBenign(address _validator, uint _blockNumber)
		external
		isValidator(msg.sender)
		isValidator(_validator)
		isRecent(_blockNumber)
	{
		emit Report(msg.sender, _validator, false);
	}

	// GETTERS

	// Called to determine the current set of validators.
	function getValidators()
		public
		view
		returns (address[])
	{
		return validators;
	}

	// Called to determine the pending set of validators.
	function getPending()
		public
		view
		returns (address[])
	{
		return pending;
	}

	// INTERNAL

	// Called when an initiated change reaches finality and is activated.
	// This method is defined with no modifiers so it can be reused by
	// contracts inheriting it (e.g. for mocking in tests).
	function finalizeChangeInternal()
		internal
	{
		validators = pending;
		finalized = true;
		emit ChangeFinalized(getValidators());
	}

	// PRIVATE

	// Log desire to change the current list.
	function initiateChange()
		private
		whenFinalized
	{
		finalized = false;
		// solium-disable-next-line security/no-block-members
		emit InitiateChange(blockhash(block.number - 1), getPending());
	}
}
