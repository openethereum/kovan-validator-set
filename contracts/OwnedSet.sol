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

// An owned validator set contract where the owner can add or remove validators.

pragma solidity ^0.4.22;

import "./interfaces/BaseOwnedSet.sol";
import "./interfaces/ValidatorSet.sol";


contract OwnedSet is ValidatorSet, BaseOwnedSet {
	// STATE

	// System address, used by the block sealer.
	address public systemAddress;

	// MODIFIERS
	modifier onlySystem() {
		require(msg.sender == systemAddress);
		_;
	}

	constructor(address[] _initial) BaseOwnedSet(_initial)
		public
	{
		systemAddress = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
	}

	// Called when an initiated change reaches finality and is activated.
	function finalizeChange()
		external
		onlySystem
	{
		baseFinalizeChange();
	}

	// MISBEHAVIOUR HANDLING

	function reportBenign(address _validator, uint256 _blockNumber)
		external
	{
		baseReportBenign(msg.sender, _validator, _blockNumber);
	}

	function reportMalicious(address _validator, uint256 _blockNumber, bytes _proof)
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
