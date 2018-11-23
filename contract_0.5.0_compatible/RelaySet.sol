pragma solidity ^0.5;

import "./interfaces/Owned.sol";
import "./interfaces/ValidatorSet.sol";
import "./RelayedOwnedSet.sol";

// A validator set contract that relays calls to a relayed validator set
// contract, which allows upgrading the relayed validator set contract. It
// provides an `initiateChange` function that allows the relayed contract to
// trigger a change, since the engine will be listening for events emitted by
// the outer relay contract.

contract RelaySet is Owned, ValidatorSet {
	// EVENTS
	event NewRelayed(address indexed old, address indexed current);

	// STATE

	// System address, used by the block sealer.
	address public systemAddress;
	// Address of the inner validator set contract
	RelayedOwnedSet public relayedSet;

	// MODIFIERS
	modifier onlySystem() {
		require(msg.sender == systemAddress);
		_;
	}

	modifier onlyRelayed() {
		require(msg.sender == address(relayedSet));
		 _;
	}

	constructor()
		public
	{
		systemAddress = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
	}

	// For innerSet
	function initiateChange(bytes32 _parentHash, address[] calldata _newSet)
		external
		onlyRelayed
	{
		emit InitiateChange(_parentHash, _newSet);
	}

	// For sealer
	function finalizeChange()
		external
		onlySystem
	{
		relayedSet.finalizeChange();
	}

	function reportBenign(address _validator, uint256 _blockNumber)
		external
	{
		relayedSet.relayReportBenign(msg.sender, _validator, _blockNumber);
	}

	function reportMalicious(address _validator, uint256 _blockNumber, bytes calldata _proof)
		external
	{
		relayedSet.relayReportMalicious(
			msg.sender,
			_validator,
			_blockNumber,
			_proof
		);
	}

	function setRelayed(address _relayedSet)
		external
		onlyOwner
	{
		emit NewRelayed(address(relayedSet) , address(_relayedSet));
	} 

	function getValidators()
		external
		view
		returns (address[] memory)
	{
		return relayedSet.getValidators();
	}
}
