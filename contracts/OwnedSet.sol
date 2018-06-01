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

import "./interfaces/Owned.sol";
import "./interfaces/ValidatorSet.sol";


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
	mapping(address => AddressStatus) pendingStatus;

	// Was the last validator change finalized. Implies validators == pending
	bool public finalized;

	// MODIFIERS
	modifier onlySystemAndNotFinalized() {
		require(msg.sender != SYSTEM_ADDRESS || finalized);
		_;
	}

	modifier whenFinalized() {
		require(!finalized);
		_;
	}

	modifier isValidator(address _someone) {
		if (pendingStatus[_someone].isIn) {
			_;
		}
	}

	modifier isPending(address _someone) {
		require(pendingStatus[_someone].isIn);
		_;
	}

	modifier isNotPending(address _someone) {
		require(!pendingStatus[_someone].isIn);
		_;
	}

	modifier isRecent(uint _blockNumber) {
		require(block.number <= _blockNumber + recentBlocks);
		_;
	}

	constructor(address[] _initial)
		public
	{
		pending = _initial;
		for (uint i = 0; i < _initial.length - 1; i++) {
			pendingStatus[_initial[i]].isIn = true;
			pendingStatus[_initial[i]].index = i;
		}
		validators = pending;
	}

	// Called when an initiated change reaches finality and is activated.
	function finalizeChange()
		external
		onlySystemAndNotFinalized
	{
		validators = pending;
		finalized = true;
		emit ChangeFinalized(getValidators());
	}

	// OWNER FUNCTIONS

	// Add a validator.
	function addValidator(address _validator)
		external
		onlyOwner
		isNotPending(_validator)
	{
		pendingStatus[_validator].isIn = true;
		pendingStatus[_validator].index = pending.length;
		pending.push(_validator);
		initiateChange();
	}

	// Remove a validator.
	function removeValidator(address _validator)
		external
		onlyOwner
		isPending(_validator)
	{
		pending[pendingStatus[_validator].index] = pending[pending.length - 1];
		delete pending[pending.length - 1];
		pending.length--;
		// Reset address status.
		delete pendingStatus[_validator].index;
		pendingStatus[_validator].isIn = false;
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
		onlyOwner
		isRecent(_blockNumber)
	{
		emit Report(msg.sender, _validator, true);
	}

	// Report that a validator has misbehaved in a benign way.
	function reportBenign(address _validator, uint _blockNumber)
		external
		onlyOwner
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
