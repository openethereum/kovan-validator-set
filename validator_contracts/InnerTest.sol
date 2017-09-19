pragma solidity ^0.4.15;

import "./RelaySet.sol";

contract InnerTest is InnerSet {
	event ChangeFinalized(address[] current_set);

	function InnerTest(address _outer) {
		outerSet = OuterSet(_outer);
	}

	address[] dummy;

	function getValidators() constant returns (address[]) {
		return dummy;
	}

	function finalizeChange() {
		ChangeFinalized(dummy);
	}

	function changeValidators() {
		outerSet.initiateChange(0, dummy);
	}
}
