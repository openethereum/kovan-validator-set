exports.assertThrowsAsync = async (fn, msg) => {
  try {
    await fn();
  } catch (err) {
    assert(err.message.includes(msg), "Expected error to include: " + msg);
    return;
  }
  assert.fail("Expected fn to throw");
};
