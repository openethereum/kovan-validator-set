pragma solidity ^0.4.8;

// Existing validators can give support to addresses.
// Support can not be added once MAX_VALIDATORS are present.
// Once given, support can be removed.
// Addresses supported by more than half of the existing validators are the validators.
// Malicious behaviour causes support removal.
// Benign misbehaviour causes supprt removal if its called again after MAX_INACTIVITY.
// Benign misbehaviour can be absolved before being called the second time.

contract MajorityList {
    // EVENTS
    event ValidatorsChanged(bytes32 indexed parent_hash, uint256 indexed nonce, address[] new_set);
    event Report(address indexed reporter, address indexed reported, bool indexed malicious);
    event Support(address indexed supporter, address indexed supported, bool indexed added);

    struct ValidatorStatus {
        // Is this a validator.
        bool isValidator;
        // Index in the validatorList.
        uint index;
        // Validator addresses which supported the address.
        VoteTracker support;
        // Keeps track of the votes given out while the address is a validator.
        address[] supported;
        // Initial benign misbehaviour time tracker.
        mapping(address => uint) firstBenign;
        // Repeated benign misbehaviour counter.
        VoteTracker benignMisbehaviour;
    }

    // Tracks the amount of support for a given address.
    struct VoteTracker {
        uint votes;
        // Keeps track of who voted for a given address at a given block, prevent double voting.
        mapping(address => bool) voted;
    }

    // Support can not be added once this number of validators is reached.
    uint public constant MAX_VALIDATORS = 30;
    // Time after which the validators will report a validator as malicious.
    uint public constant MAX_INACTIVITY = 6 hours;
    /// Last block at which the validator set was altered.
    uint public lastTransitionBlock;
    /// Number of blocks at which the validators were changed.
    uint256 public transitionNonce;
    // Current list of addresses entitled to participate in the consensus.
    address[] public validatorsList;
    // Tracker of status for each address.
    mapping(address => ValidatorStatus) validatorsStatus;

    // Each validator is initially supported by all others.
    function MajorityList() {
        validatorsList.push(0xF5777f8133aAe2734396ab1d43ca54aD11BFB737);

        if (validatorsList.length > MAX_VALIDATORS) { throw; }

        for (uint i = 0; i < validatorsList.length; i++) {
            address validator = validatorsList[i];
            validatorsStatus[validator] = ValidatorStatus({
                isValidator: true,
                index: i,
                support: VoteTracker({
                    votes: validatorsList.length
                }),
                supported: validatorsList,
                benignMisbehaviour: VoteTracker({ votes: 0 }),
            });
            for (uint j = 0; j < validatorsList.length; j++) {
                address supporter = validatorsList[j];
                validatorsStatus[validator].support.voted[supporter] = true;
                Support(supporter, validator, true);
            }
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

    // SUPPORT LOOKUP AND MANIPULATION

    // Find the total support for a given address.
    function getSupport(address validator) constant returns (uint) {
        return validatorsStatus[validator].support.votes;
    }

    function getSupported(address validator) constant returns (address[]) {
        return validatorsStatus[validator].supported;
    }

    // Vote to include a validator.
    function addSupport(address validator) only_validator not_voted(validator) free_validator_slots {
        newStatus(validator);
        validatorsStatus[validator].support.votes++;
        validatorsStatus[validator].support.voted[msg.sender] = true;
        validatorsStatus[msg.sender].supported.push(validator);
        addValidator(validator);
        Support(msg.sender, validator, true);
    }

    // Remove support for a validator.
    function removeSupport(address sender, address validator) private has_votes(sender, validator) {
        validatorsStatus[validator].support.votes--;
        validatorsStatus[validator].support.voted[sender] = false;
        Support(sender, validator, false);
        // Remove validator from the list if there is not enough support.
        removeValidator(validator);
    }

    // MALICIOUS BEHAVIOUR HANDLING

    // Called when a validator should be removed.
    function reportMalicious(address validator) only_validator {
        removeSupport(msg.sender, validator);
        Report(msg.sender, validator, true);
    }

    // BENIGN MISBEHAVIOUR HANDLING

    // Report that a validator has misbehaved in a benign way.
    function reportBenign(address validator) only_validator is_validator(validator) {
        firstBenign(validator);
        repeatedBenign(validator);
        Report(msg.sender, validator, false);
    }

    // Find the total number of repeated misbehaviour votes.
    function getRepeatedBenign(address validator) constant returns (uint) {
        return validatorsStatus[validator].benignMisbehaviour.votes;
    }

    // Track the first benign misbehaviour.
    function firstBenign(address validator) private has_not_benign_misbehaved(validator) {
        validatorsStatus[validator].firstBenign[msg.sender] = now;
    }

    // Report that a validator has been repeatedly misbehaving.
    function repeatedBenign(address validator) private has_repeatedly_benign_misbehaved(validator) {
        validatorsStatus[validator].benignMisbehaviour.votes++;
        validatorsStatus[validator].benignMisbehaviour.voted[msg.sender] = true;
        confirmedRepeatedBenign(validator);
    }

    // When enough long term benign misbehaviour votes have been seen, remove support.
    function confirmedRepeatedBenign(address validator) private agreed_on_repeated_benign(validator) {
        validatorsStatus[validator].firstBenign[msg.sender] = 0;
        validatorsStatus[validator].benignMisbehaviour.votes--;
        validatorsStatus[validator].benignMisbehaviour.voted[msg.sender] = false;
        removeSupport(msg.sender, validator);
    }

    // Absolve a validator from a benign misbehaviour.
    function absolveFirstBenign(address validator) has_benign_misbehaved(validator) {
        validatorsStatus[validator].firstBenign[msg.sender] = 0;
        if (validatorsStatus[validator].benignMisbehaviour.voted[msg.sender]) {
            validatorsStatus[validator].benignMisbehaviour.votes--;
            validatorsStatus[validator].benignMisbehaviour.voted[msg.sender] = false;
        }
    }

    // PRIVATE UTILITY FUNCTIONS

    // Add a status tracker for unknown validator.
    function newStatus(address validator) private has_no_votes(validator) {
        validatorsStatus[validator] = ValidatorStatus({
            isValidator: false,
            index: validatorsList.length,
            support: VoteTracker({ votes: 0 }),
            supported: new address[](0),
            benignMisbehaviour: VoteTracker({ votes: 0 })
        });
    }

    // ENACTMENT FUNCTIONS (called when support gets out of line with the validator list)

    // Add the validator if supported by majority.
    // Since the number of validators increases it is possible to some fall below the threshold.
    function addValidator(address validator) is_not_validator(validator) has_high_support(validator) {
        validatorsStatus[validator].index = validatorsList.length;
        validatorsList.push(validator);
        validatorsStatus[validator].isValidator = true;
        // New validator should support itself.
        validatorsStatus[validator].support.votes++;
        validatorsStatus[validator].support.voted[validator] = true;
        validatorsStatus[validator].supported.push(validator);
        logTransition();
    }

    // Remove a validator without enough support.
    // Can be called to clean low support validators after making the list longer.
    function removeValidator(address validator) is_validator(validator) has_low_support(validator) {
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
        // Reset validator status.
        validatorsStatus[validator].index = 0;
        validatorsStatus[validator].isValidator = false;
        // Remove all support given by the removed validator.
        address[] toRemove = validatorsStatus[validator].supported;
        for (uint i = 0; i < toRemove.length; i++) {
            removeSupport(validator, toRemove[i]);
        }
        delete validatorsStatus[validator].supported;
        logTransition();
    }

    // MODIFIERS

    function highSupport(address validator) constant returns (bool) {
        return getSupport(validator) > validatorsList.length/2;
    }

    function firstBenignReported(address validator) constant returns (uint) {
        return validatorsStatus[validator].firstBenign[msg.sender];
    }

    modifier has_high_support(address validator) {
        if (highSupport(validator)) _;
    }

    modifier has_low_support(address validator) {
        if (!highSupport(validator)) _;
    }

    modifier has_not_benign_misbehaved(address validator) {
        if (firstBenignReported(validator) == 0) _;
    }

    modifier has_benign_misbehaved(address validator) {
        if (firstBenignReported(validator) > 0) _;
    }

    modifier has_repeatedly_benign_misbehaved(address validator) {
        if (firstBenignReported(validator) - now > MAX_INACTIVITY) _;
    }

    modifier agreed_on_repeated_benign(address validator) {
        if (getRepeatedBenign(validator) > validatorsList.length/2) _;
    }

    modifier free_validator_slots() {
        if (validatorsList.length >= MAX_VALIDATORS) throw; _;
    }

    modifier only_validator() {
        if (!validatorsStatus[msg.sender].isValidator) throw; _;
    }

    modifier is_validator(address someone) {
        if (validatorsStatus[someone].isValidator) _;
    }

    modifier is_not_validator(address someone) {
        if (!validatorsStatus[someone].isValidator) _;
    }

    modifier not_voted(address validator) {
        if (validatorsStatus[validator].support.voted[msg.sender]) throw; _;
    }

    modifier has_no_votes(address validator) {
        if (validatorsStatus[validator].support.votes == 0) _;
    }

    modifier has_votes(address sender, address validator) {
        if (validatorsStatus[validator].support.votes > 0
            && validatorsStatus[validator].support.voted[sender]) _;
    }

    modifier on_new_block() {
        if (block.number > lastTransitionBlock) _;
    }

    // Fallback function throws when called.
    function() payable {
        throw;
    }
}
