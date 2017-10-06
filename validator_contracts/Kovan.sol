pragma solidity ^0.4.15;

import "./InnerMajoritySet.sol";
import "./libraries/AddressVotes.sol";

contract Kovan is InnerMajoritySet {
	// Used to lower the constructor cost.
	bool private initialized;

	modifier uninitialized() {
		require(!initialized);
		_;
	}

	// Each validator is initially supported by all others.
	function Kovan() public {
		pendingList = [
			// Etherscan
			0x00D6Cc1BA9cf89BD2e58009741f4F7325BAdc0ED,
			// Attores
			0x00427feae2419c15b89d1c21af10d1b6650a4d3d,
			// TenX (OneBit)
			0x4Ed9B08e6354C70fE6F8CB0411b0d3246b424d6c,
			// Melonport
			0x0020ee4Be0e2027d76603cB751eE069519bA81A1,
			// Parity
			0x0010f94b296a852aaac52ea6c5ac72e03afd032d,
			// DigixGlobal
			0x007733a1FE69CF3f2CF989F81C7b4cAc1693387A,
			// Maker
			0x00E6d2b931F55a3f1701c7389d592a7778897879,
			// Aurel
			0x00e4a10650e5a6D6001C38ff8E64F97016a1645c,
			// GridSingularity
			0x00a0a24b9f0e5ec7aa4c7389b8302fd0123194de
		];

		initialSupport.count = pendingList.length;
		for (uint i = 0; i < pendingList.length; i++) {
			address supporter = pendingList[i];
			initialSupport.inserted[supporter] = true;
		}
	}

	// Has to be called once before any other methods are called.
	function initializeValidators() public uninitialized {
		for (uint j = 0; j < pendingList.length; j++) {
			address validator = pendingList[j];
			validatorsStatus[validator] = ValidatorStatus({
				isValidator: true,
				index: j,
				support: initialSupport,
				supported: pendingList,
				benignMisbehaviour: AddressVotes.Data({ count: 0 })
			});
		}
		initialized = true;
		validatorsList = pendingList;
	}
}
