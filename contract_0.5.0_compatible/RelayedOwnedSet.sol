pragma solidity ^0.5;

import "./interfaces/BaseOwnedSet.sol";
import "./RelaySet.sol";


contract RelayedOwnedSet is BaseOwnedSet {
	RelaySet public relaySet;

	modifier onlyRelay() {
		require(msg.sender == address(relaySet));
		_;
	}

	constructor(address _relaySet, address  _owner, address[] memory _initial) BaseOwnedSet(_owner, _initial)
		public
	{
		relaySet = RelaySet(_relaySet);
	}

	function relayReportBenign(address _reporter, address _validator, uint _blockNumber)
		external
		onlyRelay
	{
		baseReportBenign(_reporter, _validator, _blockNumber);
	}

	function relayReportMalicious(
		address _reporter,
		address _validator,
		uint _blockNumber,
		bytes calldata _proof
	)
		external
		onlyRelay
	{
		baseReportMalicious(
			_reporter,
			_validator,
			_blockNumber,
			_proof
		);
	}

	function setRelay(address _relaySet)
		external
		onlyOwner
	{
		relaySet = RelaySet(_relaySet);
	}

	function finalizeChange()
		external
		onlyRelay
	{
		baseFinalizeChange();
	}

	function initiateChange()
		private
	{
		relaySet.initiateChange(blockhash(block.number - 1), pending);
	}
}
