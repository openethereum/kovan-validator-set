pragma solidity ^0.4.8;

contract ValidatorSet {
	event InitiateChange(bytes32 indexed _parent_hash, address[] _new_set);

	function getValidators() constant public returns (address[]);
	function finalizeChange() public;
}

contract ImmediateSet is ValidatorSet {
	function finalizeChange() public {}
}
