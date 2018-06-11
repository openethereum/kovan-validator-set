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

// A `OwnedSet` validator contract that is meant to be used as the inner
// contract of a `RelaySet`.

pragma solidity ^0.4.22;

import "./Owned.sol";
import "./OwnedSet.sol";
import "./RelaySet.sol";


contract InnerOwnedSet is BaseOwnedSet {
	OuterSet public outerSet;

	modifier onlyOuter() {
		require(msg.sender == address(outerSet));
		_;
	}

	constructor(address _outerSet, address[] _initial) BaseOwnedSet(_initial)
		public
	{
		outerSet = OuterSet(_outerSet);
	}

	function outerReportBenign(address _reporter, address _validator, uint _blockNumber)
		external
		onlyOuter
	{
		baseReportBenign(_reporter, _validator, _blockNumber);
	}

	function outerReportMalicious(
		address _reporter,
		address _validator,
		uint _blockNumber,
		bytes _proof
	)
		external
		onlyOuter
	{
		baseReportMalicious(
			_reporter,
			_validator,
			_blockNumber,
			_proof
		);
	}

	function setOuter(address _outer)
		external
		onlyOwner
	{
		outerSet = OuterSet(_outer);
	}

	function finalizeChange()
		external
		onlyOuter
	{
		baseFinalizeChange();
	}

	function initiateChange()
		private
	{
		outerSet.initiateChange(blockhash(block.number - 1), pending);
	}
}
