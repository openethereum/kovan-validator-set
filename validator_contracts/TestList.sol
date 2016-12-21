pragma solidity ^0.4.6;

contract TestList {
		// Accounts used for testing: "0".sha3() and "1".sha3()
    address[] public validators = [0x7d577a597b2742b498cb5cf0c26cdcd726d39e6e, 0x82a978b3f5962a5b0957d9ee9eef472ee55b42f1];
    
    // Called on every block to update node validator list.
    function get_validators() constant returns (address[]) {
        return validators;
    }
    
    // Expand the list of validators.
    function add_validator(address validator) {
        validators.push(validator);
    }

    // Remove a validator from the list.
    function remove_validator(uint index) {
        validators[index] = validators[validators.length-1];
        delete validators[validators.length-1];
        validators.length--;
    }
}
