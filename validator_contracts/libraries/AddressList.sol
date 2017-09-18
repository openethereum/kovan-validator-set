pragma solidity ^0.4.15;

library AddressList {
	struct AddressStatus {
		bool isIn;
		uint index;
	}

	struct Data {
		address[] list;
		mapping(address => AddressStatus) status;
	}

	// Return the whole list.
	function dump(Data storage self) returns (address[]) {
		return self.list;
	}

	// Number of addresses in the list.
	function count(Data storage self) constant returns (uint) {
		return self.list.length;
	}

	// Is the given address in the list.
	function contains(Data storage self, address _some) returns (bool) {
		return self.status[_some].isIn;
	}

	// Insert an address into the list.
	function insert(Data storage self, address _new) returns (bool) {
		if (self.status[_new].isIn) { return false; }
		self.list.push(_new);
		self.status[_new].index = self.list.length - 1;
		return true;
	}

	// Remove an address from the list.
	function remove(Data storage self, address _removed) returns (bool) {
		if (!self.status[_removed].isIn) { return false; }
		self.list[self.status[_removed].index] = self.list[self.list.length - 1];
		delete self.list[self.list.length - 1];
		self.list.length--;
		// Reset address status.
		delete self.status[_removed].index;
		self.status[_removed].isIn = false;
		return true;
	}
}
