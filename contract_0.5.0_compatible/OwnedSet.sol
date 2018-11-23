pragma solidity ^0.5;

import "./interfaces/BaseOwnedSet.sol";
import "./interfaces/ValidatorSet.sol";

// An owned validator set contract where the owner can add or remove validators.

contract OwnedSet is ValidatorSet, BaseOwnedSet {

	constructor(address _owner, address[] memory _initial) BaseOwnedSet(_owner, _initial) 
	public {}

	// Called when an initiated change reaches finality and is activated.
	function finalizeChange()
		external
		onlyOwner
	{
		baseFinalizeChange();
	}

	// MISBEHAVIOUR HANDLING

	function reportBenign(address _validator, uint256 _blockNumber)
		external
	{
		baseReportBenign(msg.sender, _validator, _blockNumber);
	}

	function reportMalicious(address _validator, uint256 _blockNumber, bytes calldata _proof)
		external
	{
		baseReportMalicious(
			msg.sender,
			_validator,
			_blockNumber,
			_proof
		);
	}

	// PRIVATE

	// Log desire to change the current list.
	function initiateChange()
		private
	{
		emit InitiateChange(blockhash(block.number - 1), pending);
	}
}
