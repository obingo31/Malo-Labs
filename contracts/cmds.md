# Basic run
echidna test/TestStaker.sol --contract TestStaker --config test/echidna.yaml

# With specific property
echidna test/TestStaker.sol --contract TestStaker --test-mode property

# With coverage
echidna test/TestStaker.sol --contract TestStaker --coverage

# Save corpus for replay
echidna test/TestStaker.sol --contract TestStaker --corpus-dir ./corpus