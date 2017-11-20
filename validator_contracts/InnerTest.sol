pragma solidity ^0.4.15;

import "./interfaces/RelaySet.sol";

contract InnerTest is InnerSet {
	event ChangeFinalized(address[] current_set);

	function InnerTest(address _outer) public {
		outerSet = OuterSet(_outer);
	}

	address[] dummy;

	function getValidators() public constant returns (address[]) {
		return dummy;
	}

	function finalizeChange() public {
		ChangeFinalized(dummy);
	}

	function changeValidators() public {
		outerSet.initiateChange(0, dummy);
	}
}
