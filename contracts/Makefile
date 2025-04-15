.PHONY: test clean clean-echidna clean-forge

# This Makefile is used to run tests and coverage for the contracts in the Malo-Labs repository.

clean: clean-echidna clean-forge
	rm -rf ./coverage

clean-echidna:
	rm -rf ./test/echidna/_corpus
	rm -rf ./test/echidna/_exploration
	rm -rf ./test/echidna/_assertion
	rm -rf ./test/echidna/_call_sequences

clean-forge:
	forge clean

build:
	forge build
	@echo "Build complete"

test:
	forge test

gas:
	WRITE_GAS_REPORT=true forge test --mp test/gas/ --gas-report/*.g.sol --isolate
	@echo "Gas report complete"
	forge coverage --report gas --report-path coverage/gas-report --report-format html
	@echo "Gas coverage report complete"

# Invariants Testing
ECHIDNA_CONFIG := ./test/echidna/echidna_config.yaml
CORPUS_DIR := ./test/echidna/_corpus

echidna:
	echidna ./test/echidna/Setup.t.sol \
		--contract Setup \
		--config $(ECHIDNA_CONFIG) \
		--corpus-dir $(CORPUS_DIR)

echidna-assert:
	echidna ./test/echidna/Setup.t.sol \
		--contract Setup \
		--test-mode assertion \
		--config $(ECHIDNA_CONFIG) \
		--corpus-dir $(CORPUS_DIR)

echidna-explore:
	echidna ./test/echidna/Setup.t.sol \
		--contract Setup \
		--test-mode exploration \
		--config $(ECHIDNA_CONFIG) \
		--corpus-dir $(CORPUS_DIR)

echidna-crytic:
	echidna . \
		--contract CryticTester \
		--config echidna.yaml \
		--format text \
		--workers 16 \
		--test-limit 1000000 \
		--test-mode assertion
		--corpus-dir $(CORPUS_DIR)
		--test-mode assertion \
		--config $(ECHIDNA_CONFIG) \

echidna-config:
	echidna ./test/echidna/Tester.t.sol \
		--contract Tester \
		--config echidna_config.yaml \
		--format text \
		--workers 16 \
		--test-limit 1000000 \
		--test-mode assertion \
		--corpus-dir $(CORPUS_DIR)

# Symbolic Testing
halmos:
	halmos --solver-timeout-assertion 10000



# Fuzz Testing
medusa:
	medusa fuzz --config ./medusa.json