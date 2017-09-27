pragma solidity ^0.4.8;

// Some addresses are admins.
// Admin can add or remove another admin or a validator.

contract AdminList {
    // EVENTS
    event ValidatorsChanged(bytes32 indexed parent_hash, uint256 indexed nonce, address[] new_set);
    event Report(address indexed reporter, address indexed reported, bool indexed malicious);

    /// Admin status.
    mapping(address => bool) public isAdmin;
    /// Last block at which the validator set was altered.
    uint public lastTransitionBlock;
    /// Number of blocks at which the validators were changed.
    uint256 public transitionNonce;
    // Current list of addresses entitled to participate in the consensus.
    address[] public validatorsList;
    // Tracker validator indices.
    mapping(address => uint) validatorIndex;

    // Each validator is initially supported by all others.
    function AdminList() {
        isAdmin[0xF5777f8133aAe2734396ab1d43ca54aD11BFB737] = true;
        validatorsList.push(0xF5777f8133aAe2734396ab1d43ca54aD11BFB737);

        for (uint i = 0; i < validatorsList.length; i++) {
            address validator = validatorsList[i];
            validatorIndex[validator] = i;
            logTransition();
        }
    }

    // Called on every block to update node validator list.
    function getValidators() constant returns (address[]) {
        return validatorsList;
    }

    function logTransition() private {
        incrementTransitionNonce();
        ValidatorsChanged(block.blockhash(block.number - 1), transitionNonce, validatorsList);
    }

    function incrementTransitionNonce() private on_new_block {
        lastTransitionBlock = block.number;
        transitionNonce += 1;
    }

    // ADMIN FUNCTIONS

    // Add a validator.
    function addValidator(address validator) only_admin {
        validatorIndex[validator] = validatorsList.length;
        validatorsList.push(validator);
        logTransition();
    }

    // Remove a validator.
    function removeValidator(address validator) only_admin {
        uint removedIndex = validatorIndex[validator];
        // Can not remove the last validator.
        uint lastIndex = validatorsList.length-1;
        address lastValidator = validatorsList[lastIndex];
        // Override the removed validator with the last one.
        validatorsList[removedIndex] = lastValidator;
        // Update the index of the last validator.
        validatorIndex[lastValidator] = removedIndex;
        delete validatorsList[lastIndex];
        validatorsList.length--;
        // Reset validator status.
        validatorIndex[validator] = 0;
        logTransition();
    }

    // Add an admin.
    function addAdmin(address admin) only_admin {
        isAdmin[admin] = true;
    }

    // Remove an admin.
    function removeAdmin(address admin) only_admin {
        isAdmin[admin] = false;
    }

    // MISBEHAVIOUR HANDLING

    // Called when a validator should be removed.
    function reportMalicious(address validator) only_admin {
        Report(msg.sender, validator, true);
    }

    // Report that a validator has misbehaved in a benign way.
    function reportBenign(address validator) only_admin {
        Report(msg.sender, validator, false);
    }

    // MODIFIERS

    modifier only_admin() {
        if (!isAdmin[msg.sender]) throw; _;
    }

    modifier on_new_block() {
        if (block.number > lastTransitionBlock) _;
    }

    // Fallback function throws when called.
    function() payable {
        throw;
    }
}
