// Copyright 2018 Parity Technologies Ltd.
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

// A `OwnedSet` validator contract that is meant to be relayed by a `RelaySet`
// contract.

pragma solidity ^0.4.24;

import "./interfaces/BaseOwnedSet.sol";
import "./RelaySet.sol";


contract RelayedOwnedSet is BaseOwnedSet {
	RelaySet public relaySet;

	modifier onlyRelay() {
		require(msg.sender == address(relaySet));
		_;
	}

	constructor(address _relaySet, address[] _initial) BaseOwnedSet(_initial)
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
		bytes _proof
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
