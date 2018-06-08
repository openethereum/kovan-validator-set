"use strict";

const TestOuterSet = artifacts.require("TestOuterSet");
const TestInnerOwnedSet = artifacts.require("TestInnerOwnedSet");

contract("TestInnerOwnedSet", accounts => {
  const assertThrowsAsync = async (fn, msg) => {
    try {
      await fn();
    } catch (err) {
      assert(err.message.includes(msg), "Expected error to include: " + msg);
      return;
    }
    assert.fail("Expected fn to throw");
  };

  const OWNER = accounts[0];
  const SYSTEM = accounts[9];
  const INITIAL_VALIDATORS = [accounts[0], accounts[1], accounts[2]];

  let _outerSet;
  const outerSet = async () => {
    if (_outerSet === undefined) {
      _outerSet = await TestOuterSet.new(
        SYSTEM,
      );
      await _outerSet.setInner((await innerOwnedSet()).address);
    }

    return _outerSet;
  };

  let _innerOwnedSet;
  const innerOwnedSet = async () => {
    if (_innerOwnedSet === undefined) {
      _innerOwnedSet = await TestInnerOwnedSet.new(
        (await outerSet()).address,
        INITIAL_VALIDATORS,
      );
    }

    return _innerOwnedSet;
  };

  it("should initialize the pending and validators set on creation", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();

    const validators = await outer.getValidators();
    const pending = await inner.getPending();

    const expected = INITIAL_VALIDATORS;

    // both the pending and current validator set should point to the initial set
    assert.deepEqual(validators, expected);
    assert.deepEqual(pending, expected);

    const finalized = await outer.finalized();

    // the change should not be finalized
    assert(!finalized);

    // every validator should be added to the `pendingStatus` map
    for (let [index, acc] of expected.entries()) {
      let [isIn, idx] = await inner.getStatus(acc);
      assert(isIn);
      assert.equal(idx, index);
    }
  });

  it("should allow the system to finalize changes", async () => {
    const set = await outerSet();
    const watcher = set.ChangeFinalized();

    // only the system address can finalize changes
    await assertThrowsAsync(
      () => set.finalizeChange(),
      "revert",
    );

    // we successfully finalize the change
    await set.finalizeChange({ from: SYSTEM });

    // the initial validator set should be finalized
    const finalized = await set.finalized();
    assert(finalized);

    // a `ChangeFinalized` event should be emitted
    const events = await watcher.get();

    assert.equal(events.length, 1);
    assert.deepEqual(events[0].args.currentSet, INITIAL_VALIDATORS);

    // abort if there's no change to finalize
    await assertThrowsAsync(
      () => set.finalizeChange({ from: SYSTEM }),
      "revert",
    );
  });

  it("should allow the owner to add new validators", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();
    const watcher = outer.InitiateChange();

    // only the owner can add new validators
    await assertThrowsAsync(
      () => inner.addValidator(accounts[3], { from: accounts[1] }),
      "revert",
    );

    // we successfully add a new validator
    await inner.addValidator(accounts[3], { from: OWNER });

    // a `InitiateChange` event should be emitted
    const events = await watcher.get();

    const newSet = INITIAL_VALIDATORS.concat(accounts[3]);

    const parent = await web3.eth.getBlock(web3.eth.blockNumber - 1);
    assert.equal(events.length, 1);
    assert.equal(events[0].args._parentHash, parent.hash);
    assert.deepEqual(events[0].args._newSet, newSet);

    // this change is not finalized yet
    const finalized = await outer.finalized();
    assert(!finalized);

    // the pending set should be updated
    assert.deepEqual(
      await inner.getPending(),
      newSet,
    );

    // the validator set should stay the same
    assert.deepEqual(
      await outer.getValidators(),
      INITIAL_VALIDATORS,
    );

    // `pendingStatus` should be updated
    const [isIn, index] = await inner.getStatus(accounts[3]);
    assert(isIn);
    assert.equal(index, 3);

    // we successfully finalize the change
    await outer.finalizeChange({ from: SYSTEM });

    // the validator set should be updated
    assert.deepEqual(
      await outer.getValidators(),
      newSet,
    );
  });

  it("should abort when adding a duplicate validator", async () => {
    const set = await innerOwnedSet();
    // we successfully add a new validator
    await assertThrowsAsync(
      () => set.addValidator(accounts[3], { from: OWNER }),
      "revert",
    );
  });

  it("should allow the owner to remove a validator", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();
    const watcher = outer.InitiateChange();

    // only the owner can remove validators
    await assertThrowsAsync(
      () => inner.removeValidator(accounts[3], { from: accounts[1] }),
      "revert",
    );

    // we successfully remove a validator
    await inner.removeValidator(accounts[3], { from: OWNER });

    // a `InitiateChange` event should be emitted
    const events = await watcher.get();

    const parent = await web3.eth.getBlock(web3.eth.blockNumber - 1);
    assert.equal(events.length, 1);
    assert.equal(events[0].args._parentHash, parent.hash);
    assert.deepEqual(events[0].args._newSet, INITIAL_VALIDATORS);

    // this change is not finalized yet
    const finalized = await outer.finalized();
    assert(!finalized);

    // the pending set should be updated
    assert.deepEqual(
      await inner.getPending(),
      INITIAL_VALIDATORS,
    );

    // the validator set should stay the same
    assert.deepEqual(
      await outer.getValidators(),
      INITIAL_VALIDATORS.concat(accounts[3]),
    );

    // `pendingStatus` should be updated
    const [isIn, index] = await inner.getStatus(accounts[3]);
    assert(!isIn);
    assert.equal(index, 0);

    // we successfully finalize the change
    await outer.finalizeChange({ from: SYSTEM });

    // the validator set should be updated
    assert.deepEqual(
      await outer.getValidators(),
      INITIAL_VALIDATORS,
    );
  });

  it("should abort when trying to remove non-existent validator", async () => {
    const set = await innerOwnedSet();

    // exists in `pendingStatus` with `isIn` set to false
    await assertThrowsAsync(
      () => set.removeValidator(accounts[3], { from: OWNER }),
      "revert",
    );

    // non-existent in `pendingStatus`
    await assertThrowsAsync(
      () => set.removeValidator(accounts[8], { from: OWNER }),
      "revert",
    );
  });

  it("should only allow one change per epoch", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();

    await inner.addValidator(accounts[3], { from: OWNER });

    // disallowed because previous change hasn't been finalized yet
    await assertThrowsAsync(
      () => inner.removeValidator(accounts[2], { from: OWNER }),
      "revert",
    );

    await outer.finalizeChange({ from: SYSTEM });

    // after finalizing it should work successfully
    await inner.removeValidator(accounts[3], { from: OWNER });

    assert.deepEqual(
      await inner.getPending(),
      INITIAL_VALIDATORS,
    );
  });

  it("should allow current validators to report misbehaviour", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();
    const watcher = inner.Report();

    // only current validators can report misbehaviour
    await assertThrowsAsync(
      () => outer.reportMalicious(
        INITIAL_VALIDATORS[0],
        web3.eth.blockNumber - 1,
        [],
        { from: accounts[8] },
      ),
      "revert",
    );

    await assertThrowsAsync(
      () => outer.reportBenign(
        INITIAL_VALIDATORS[0],
        web3.eth.blockNumber - 1,
        { from: accounts[8] },
      ),
      "revert",
    );

    await inner.getStatus(INITIAL_VALIDATORS[0]);

    // successfully report malicious misbehaviour
    await outer.reportMalicious(
      INITIAL_VALIDATORS[0],
      web3.eth.blockNumber - 1,
      [],
      { from: INITIAL_VALIDATORS[1] },
    );

    // it should emit a `Report` event
    let events = await watcher.get();

    assert.equal(events.length, 1);
    assert.equal(events[0].args.reporter, INITIAL_VALIDATORS[1]);
    assert.equal(events[0].args.reported, INITIAL_VALIDATORS[0]);
    assert(events[0].args.malicious);

    // successfully report benign misbehaviour
    await outer.reportBenign(
      INITIAL_VALIDATORS[0],
      web3.eth.blockNumber - 1,
      { from: INITIAL_VALIDATORS[1] },
    );

    // it should emit a `Report` event
    events = await watcher.get();

    assert.equal(events.length, 1);
    assert.equal(events[0].args.reporter, INITIAL_VALIDATORS[1]);
    assert.equal(events[0].args.reported, INITIAL_VALIDATORS[0]);
    assert(!events[0].args.malicious);
  });

  it("should allow the owner to set required recency of misbehavior reports", async () => {
    const set = await innerOwnedSet();

    // only the owner can call `setRecentBlocks`
    await assertThrowsAsync(
      () => set.setRecentBlocks(1, { from: accounts[1] }),
      "revert",
    );

    await set.setRecentBlocks(1, { from: OWNER });

    const recentBlocks = await set.recentBlocks();
    assert.equal(recentBlocks, 1);
  });

  it("should ignore old misbehaviour reports", async () => {
    const set = await outerSet();

    await assertThrowsAsync(
      () => set.reportBenign(
        accounts[0],
        web3.eth.blockNumber - 1,
        { from: OWNER },
      ),
      "revert",
    );
  });

  it("should ignore reports from addresses that are not validators", async () => {
    const outer = await outerSet();
    const inner = await innerOwnedSet();

    await inner.setRecentBlocks(20, { from: OWNER });

    // exists in `pendingStatus` with `isIn` set to false
    await assertThrowsAsync(
      () => outer.reportBenign(
        accounts[3],
        web3.eth.blockNumber,
        { from: OWNER },
      ),
      "revert",
    );

    // non-existent in `pendingStatus`
    await assertThrowsAsync(
      () => outer.reportBenign(
        accounts[8],
        web3.eth.blockNumber,
        { from: OWNER },
      ),
      "revert",
    );
  });

  it("should allow the owner of the contract to transfer ownership of the contract", async () => {
    const set = await innerOwnedSet();
    const watcher = set.NewOwner();

    // only the owner of the contract can transfer ownership
    await assertThrowsAsync(
      () => set.setOwner(accounts[1], { from: accounts[1] }),
      "revert",
    );

    let owner = await set.owner();
    assert.equal(owner, accounts[0]);

    // we successfully transfer ownership of the contract
    await set.setOwner(accounts[1]);

    // the `owner` should point to the new owner
    owner = await set.owner();
    assert.equal(owner, accounts[1]);

    // it should emit a `NewOwner` event
    const events = await watcher.get();

    assert.equal(events.length, 1);
    assert.equal(events[0].args.old, accounts[0]);
    assert.equal(events[0].args.current, accounts[1]);

    // the old owner can no longer set a new owner
    await assertThrowsAsync(
      () => set.setOwner(accounts[0], { from: accounts[0] }),
      "revert",
    );
  });
});
