pragma solidity ^0.5;

import "./Owned.sol";


// An owned validator set contract where the owner can add or remove validators.
// This is an abstract contract that provides the base logic for adding/removing
// validators and provides base implementations for the `ValidatorSet`
// interface. The base implementations of the misbehavior reporting functions
// perform validation on the reported and reporter validators according to the
// currently active validator set. The base implementation of `finalizeChange`
// validates that there are existing unfinalized changes.

contract BaseOwnedSet is Owned {
	// EVENTS
	event ChangeFinalized(address[] currentSet);

	// STATE

	// Was the last validator change finalized. Implies validators == pending
	bool public finalized;

	// TYPES
	struct AddressStatus {
		bool isIn;
		uint index;
	}

	// EVENTS
	event Report(address indexed reporter, address indexed reported, bool indexed malicious, bytes _proof);

	// STATE
	uint public recentBlocks = 20;

	// Current list of addresses entitled to participate in the consensus.
	address[] validators;
	address[] pending;
	mapping(address => AddressStatus) status;

	// MODIFIERS

	/// Asserts whether a given address is currently a validator. A validator
	/// that is pending to be added is not considered a validator, only when
	/// that change is finalized will this method return true. A validator that
	/// is pending to be removed is immediately not considered a validator
	/// (before the change is finalized).
	///
	/// For the purposes of this contract one of the consequences is that you
	/// can't report on a validator that is currently active but pending to be
	/// removed. This is a compromise for simplicity since the reporting
	/// functions only emit events which can be tracked off-chain.
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

	modifier whenFinalized() {
		require(finalized);
		_;
	}

	modifier whenNotFinalized() {
		require(!finalized);
		_;
	}

	constructor(address _owner, address[] memory _initial) Owned(_owner)
		public
	{
		pending = _initial;
		for (uint i = 0; i < _initial.length; i++) {
			status[_initial[i]].isIn = true;
			status[_initial[i]].index = i;
		}
		validators = pending;
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
		delete status[_validator];
	}

	function setRecentBlocks(uint _recentBlocks)
		external
		onlyOwner
	{
		recentBlocks = _recentBlocks;
	}

	// GETTERS

	// Called to determine the current set of validators.
	function getValidators()
		external
		view
		returns (address[] memory)
	{
		return validators;
	}

	// Called to determine the pending set of validators.
	function getPending()
		external
		view
		returns (address[] memory)
	{
		return pending;
	}

	// INTERNAL

	// Report that a validator has misbehaved in a benign way.
	function baseReportBenign(address _reporter, address _validator, uint _blockNumber)
		internal
		isValidator(_reporter)
		isValidator(_validator)
		isRecent(_blockNumber)
	{
		emit Report(_reporter, _validator, false, "");
	}

	// Report that a validator has misbehaved maliciously.
	function baseReportMalicious(
		address _reporter,
		address _validator,
		uint _blockNumber,
		bytes memory _proof
	)
		internal
		isValidator(_reporter)
		isValidator(_validator)
		isRecent(_blockNumber)
	{
		emit Report(_reporter, _validator, true, _proof);
	}

	// Called when an initiated change reaches finality and is activated.
	function baseFinalizeChange()
		internal
		whenNotFinalized
	{
		validators = pending;
		finalized = true;
		emit ChangeFinalized(validators);
	}
}
