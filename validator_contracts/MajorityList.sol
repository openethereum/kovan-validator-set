pragma solidity ^0.4.8;

// Existing validators can give support to addresses.
// Once given support can be removed.
// Addresses supported by more than half of the existing validators are the validators.
// Both reporting functions simply remove support.
contract MajorityList {
    event ValidatorSet(bool indexed added, address indexed validator);
    event Report(address indexed reporter, address indexed reported, bool indexed malicious);
    event Support(address indexed supporter, address indexed supported, bool indexed added);

    struct ValidatorStatus {
        // Is this a validator.
        bool isValidator;
        // Index in the validatorList.
        uint index;
        // Validator addresses which supported the address.
        SupportTracker support;
        // Keeps track of the votes given out while the address is a validator.
        address[] supported;
    }

    // Tracks the amount of support for a given address.
    struct SupportTracker {
        uint votes;
        // Keeps track of who voted for a given address, prevent double voting.
        mapping(address => bool) voted;
    }

    // Support can not be added once this number of validators is reached.
    uint maxValidators = 30;
    // Accounts used for testing: "0".sha3() and "1".sha3()
    address[] public validatorsList;
    mapping(address => ValidatorStatus) validatorsStatus;

    // Each validator is initially supported by all others.
    function MajorityList() {
        validatorsList.push(0xF5777f8133aAe2734396ab1d43ca54aD11BFB737);

        if (validatorsList.length > maxValidators) { throw; }

        for (uint i = 0; i < validatorsList.length; i++) {
            address validator = validatorsList[i];
            validatorsStatus[validator] = ValidatorStatus({
                isValidator: true,
                index: i,
                support: SupportTracker({
                    votes: validatorsList.length
                }),
                supported: validatorsList
            });
            for (uint j = 0; j < validatorsList.length; j++) {
                address supporter = validatorsList[j];
                validatorsStatus[validator].support.voted[supporter] = true;
                Support(supporter, validator, true);
            }
            ValidatorSet(true, validator);
        }
    }

    // Called on every block to update node validator list.
    function getValidators() constant returns (address[]) {
        return validatorsList;
    }

    // Find the total support for a given address.
    function getSupport(address validator) constant returns (uint) {
        return validatorsStatus[validator].support.votes;
    }

    // Vote to include a validator.
    function addSupport(address validator) onlyValidator notVoted(validator) freeValidatorSlots {
        newStatus(validator);
        validatorsStatus[validator].support.votes++;
        validatorsStatus[validator].support.voted[msg.sender] = true;
        validatorsStatus[msg.sender].supported.push(validator);
        addValidator(validator);
        Support(msg.sender, validator, true);
    }

    // Called when a validator should be removed.
    function reportMalicious(address validator) onlyValidator isValidator(validator) {
        removeSupport(msg.sender, validator);
        Report(msg.sender, validator, true);
    }

    // Called when a validator should be removed.
    function reportBenign(address validator) onlyValidator isValidator(validator) {
        Report(msg.sender, validator, false);
    }

    // Remove support for a validator.
    function removeSupport(address sender, address validator) private hasVotes(sender, validator) {
        validatorsStatus[validator].support.votes--;
        validatorsStatus[validator].support.voted[sender] = false;
        Support(sender, validator, false);
        // Remove validator from the list if there is not enough support.
        removeValidator(validator);
    }

    // Add a status tracker for unknown validator.
    function newStatus(address validator) private hasNoVotes(validator) {
        validatorsStatus[validator] = ValidatorStatus({
            isValidator: false,
            index: validatorsList.length,
            support: SupportTracker({ votes: 0 }),
            supported: new address[](0)
        });
    }

    // Add the validator if supported by majority.
    // Since the number of validators increases it is possible to some fall below the threshold.
    function addValidator(address validator) private isNotValidator(validator) hasHighSupport(validator) {
        validatorsStatus[validator].index = validatorsList.length;
        validatorsList.push(validator);
        validatorsStatus[validator].isValidator = true;
        // New validator should support itself.
        validatorsStatus[validator].support.votes++;
        validatorsStatus[validator].support.voted[validator] = true;
        validatorsStatus[validator].supported.push(validator);
        ValidatorSet(true, validator);
    }

    // Remove a validator without enough support.
    // Can be called to clean low support validators after making the list longer.
    function removeValidator(address validator) hasLowSupport(validator) {
        uint removedIndex = validatorsStatus[validator].index;
        // Can not remove the last validator.
        uint lastIndex = validatorsList.length-1;
        address lastValidator = validatorsList[lastIndex];
        // Override the removed validator with the last one.
        validatorsList[removedIndex] = lastValidator;
        // Update the index of the last validator.
        validatorsStatus[lastValidator].index = removedIndex;
        delete validatorsList[lastIndex];
        validatorsList.length--;
        validatorsStatus[validator].index = 0;
        validatorsStatus[validator].isValidator = false;
        // Remove all support given by the removed validator.
        address[] toRemove = validatorsStatus[validator].supported;
        for (uint i = 0; i < toRemove.length; i++) {
            removeSupport(validator, toRemove[i]);
        }
        delete validatorsStatus[validator].supported;
        ValidatorSet(false, validator);
    }

    function highSupport(address validator) constant returns (bool) {
        return getSupport(validator) > validatorsList.length/2;
    }

    modifier hasHighSupport(address validator) {
        if (highSupport(validator)) _;
    }

    modifier hasLowSupport(address validator) {
        if (!highSupport(validator)) _;
    }

    modifier freeValidatorSlots() {
        if (validatorsList.length >= maxValidators) throw; _;
    }

    modifier onlyValidator() {
        if (!validatorsStatus[msg.sender].isValidator) throw; _;
    }

    modifier isValidator(address someone) {
        if (!validatorsStatus[someone].isValidator) throw; _;
    }

    modifier isNotValidator(address someone) {
        if (!validatorsStatus[someone].isValidator) _;
    }

    modifier notVoted(address validator) {
        if (validatorsStatus[validator].support.voted[msg.sender]) throw; _;
    }

    modifier hasNoVotes(address validator) {
        if (validatorsStatus[validator].support.votes == 0) _;
    }

    modifier hasVotes(address sender, address validator) {
        if (validatorsStatus[validator].support.votes > 0
            && validatorsStatus[validator].support.voted[sender]) _;
    }
}
