pragma solidity ^0.4.6;

contract MajorityList {
    struct ValidatorStatus {
        // Index in the validatorList.
        uint index;
        // Validator addresses which supported the validator.
        SupportTracker support;
    }
    
    // Tracks the amount of support for a given validator.
    struct SupportTracker {
        uint votes;
        // Prevent double voting.
        mapping(address => bool) voted;
    }
    
	// Accounts used for testing: "0".sha3() and "1".sha3()
    address[] public validatorsList = [0x7d577a597b2742b498cb5cf0c26cdcd726d39e6e, 0x82a978b3f5962a5b0957d9ee9eef472ee55b42f1];
    mapping(address => ValidatorStatus) validatorsStatus;
    
    // Each validator is initially supported by all others.
    function MajorityList() {
        for (uint i = 0; i < validatorsList.length; i++) {
            address validator = validatorsList[i];
            validatorsStatus[validator] = ValidatorStatus({
                index: i,
                support: SupportTracker({
                    votes: validatorsList.length
                })
            });
            for (uint j = 0; j < validatorsList.length; j++) {
                validatorsStatus[validator].support.voted[validatorsList[j]] = true;
            }
        }
    }
    
    // Called on every block to update node validator list.
    function getValidators() constant returns (address[]) {
        return validatorsList;
    }
    
    // Vote to include a validator.
    function supportValidator(address validator) onlyValidator notVoted(validator) {
        newStatus(validator);
        validatorsStatus[validator].support.votes++;
        addValidator(validator);
        validatorsStatus[validator].support.voted[msg.sender] = true;
    }

    // Called when a validator should be removed.
    function reportMalicious(address validator) onlyValidator {
        removeSupport(msg.sender, validator);
        removeValidator(validator);
    }
    
    // Called when a validator should be removed.
    function reportBenign(address validator) onlyValidator {
        reportMalicious(validator);
    }

    // Remove support for a validator.
    function removeSupport(address sender, address validator) private hasVotes(sender, validator) {
        validatorsStatus[validator].support.votes--;
        validatorsStatus[validator].support.voted[sender] = false;
        // Remove validator from the list if there is not enough support.
        removeValidator(validator);
    }
    
    // Add a status tracker for unknown validator.
    function newStatus(address validator) private hasNoVotes(validator) {
        validatorsStatus[validator] = ValidatorStatus({
            index: validatorsList.length,
            support: SupportTracker({ votes: 0 })
        });
    }

    // Add the validator if supported by majority.
    function addValidator(address validator) private hasHighSupport(validator) {
        validatorsStatus[validator].index = validatorsList.length;
        validatorsList.push(validator);
    }

    // Remove a validator without enough support.
    function removeValidator(address validator) private hasLowSupport(validator) {
        uint removedIndex = validatorsStatus[validator].index;
        uint lastIndex = validatorsList.length-1;
        address lastValidator = validatorsList[lastIndex];
        // Override the removed validator with the last one.
        validatorsList[removedIndex] = lastValidator;
        // Update the index of the last validator.
        validatorsStatus[lastValidator].index = removedIndex;
        delete validatorsList[lastIndex];
        validatorsList.length--;
        validatorsStatus[validator].index = 0;
        // Remove all support given by the removed validator.
        for (uint i = 0; i < validatorsList.length; i++) {
            removeSupport(validator, validatorsList[i]);
        }
    }
    
    function highSupport(address validator) returns (bool) {
        return validatorsStatus[validator].support.votes > validatorsList.length/2;
    }
    
    modifier hasNoVotes(address validator) {
        if (validatorsStatus[validator].support.votes == 0) _;
    }
    
    modifier hasHighSupport(address validator) {
        if (highSupport(validator)) _;
    }
    
    modifier hasLowSupport(address validator) {
        if (!highSupport(validator)) _;
    }
    
    modifier onlyValidator() {
        if (validatorsStatus[msg.sender].support.votes <= validatorsList.length / 2) throw; _;
    }
    
    modifier notVoted(address validator) {
        if (validatorsStatus[validator].support.voted[msg.sender]) throw; _;
    }
    
    modifier hasVotes(address sender, address validator) {
        if (validatorsStatus[validator].support.votes > 0
            && validatorsStatus[validator].support.voted[sender]) _;
    }
}
