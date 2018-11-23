pragma solidity ^0.5;


contract Owned {
	event NewOwner(address indexed old, address indexed current);

	address public owner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	constructor(address _owner)
		public
	{
		owner = _owner;
	}

	function setOwner(address _new)
		external
		onlyOwner
	{
		emit NewOwner(owner, _new);
		owner = _new;
	}
}
