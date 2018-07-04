pragma solidity ^0.4.24;


contract Migrations {
	address public owner = msg.sender;
	uint public lastCompletedMigration;

	modifier restricted() {
		if (msg.sender == owner) {
			_;
		}
	}

	function setCompleted(uint completed) public restricted {
		lastCompletedMigration = completed;
	}

	function upgrade(address newAddress) public restricted {
		Migrations upgraded = Migrations(newAddress);
		upgraded.setCompleted(lastCompletedMigration);
	}
}
