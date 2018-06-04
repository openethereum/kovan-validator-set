"use strict";

const TestOwnedSet = artifacts.require("./TestOwnedSet.sol");

contract("TestOwnedSet", accounts => {
  const assertThrowsAsync = async (fn, msg) => {
    try {
      await fn();
    } catch (err) {
      assert(err.message.includes(msg), "Expected error to include: " + msg);
      return;
    }
    assert.fail("Expected fn to throw");
  };

  const SYSTEM = accounts[9];
  const INITIAL_VALIDATORS = [accounts[0], accounts[1], accounts[2]];

  let _ownedSet;
  const ownedSet = async () => {
    if (_ownedSet === undefined) {
      _ownedSet = await TestOwnedSet.new(
        SYSTEM,
        INITIAL_VALIDATORS,
      );
    }

    return _ownedSet;
  };

  it("should initialize the pending and validators set on creation", async () => {
    const set = await ownedSet();

    const validators = await set.getValidators();
    const pending = await set.getPending();

    const expected = INITIAL_VALIDATORS;

    // both the pending and current validator set should point to the initial set
    assert.deepEqual(validators, expected);
    assert.deepEqual(pending, expected);

    const finalized = await set.finalized();

    // the change should not be finalized
    assert(!finalized);

    // every validator should be added to the `pendingStatus` map
    for (let [index, acc] of expected.entries()) {
      let [isIn, idx] = await set.getPendingStatus(acc);
      assert(isIn);
      assert.equal(idx, index);
    }
  });
});
