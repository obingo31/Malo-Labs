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
	echidna ./test/echidna/Setup.sol \
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

CONTAINER_NAME = eigenlayer-contracts

.PHONY: install-hooks
install-hooks:
	cp bin/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

.PHONY: install-deps
install-deps:
	./bin/install-deps.sh

.PHONY: deps
deps: clean-deps install-all-deps verify-deps install-hooks install-deps

.PHONY: compile
compile:
	forge b

.PHONY: bindings
bindings: compile
	./bin/compile-bindings.sh

.PHONY: all
all: compile bindings

.PHONY: gha
gha:
	git config --global --add safe.directory "*"
	forge install
	forge b
	./bin/compile-bindings.sh

.PHONY: docker
docker:
	docker build --progress=plain -t ${CONTAINER_NAME}:latest .

.PHONY: compile-in-docker
compile-in-docker:
	docker run -v $(PWD):/build -w /build --rm -it ${CONTAINER_NAME}:latest bash -c "make compile"

.PHONY: bindings-in-docker
bindings-in-docker:
	docker run -v $(PWD):/build -w /build --rm -it ${CONTAINER_NAME}:latest bash -c "make bindings"

.PHONY: all-in-docker
all-in-docker:
	docker run -v $(PWD):/build -w /build --rm -it ${CONTAINER_NAME}:latest bash -c "make all"

.PHONY: gha-docker
gha-docker:
	docker run -v $(PWD):/build -w /build --rm -i ${CONTAINER_NAME}:latest bash -c "make gha"

.PHONY: storage-report
storage-report:
	bash "bin/storage-report.sh" "docs/storage-report/"

.PHONY: fix-typos
fix-typos:
	typos --config .github/configs/typos-cli.toml --write-changes

.PHONY: fmt
fmt:
	forge fmt; FOUNDRY_PROFILE=test forge fmt

.PHONY: update-deps
update-deps:
	forge update

.PHONY: install-all-deps
install-all-deps:
	forge install foundry-rs/forge-std@v1.7.4 --no-commit
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.1 --no-commit
	forge install Recon-Fuzz/setup-helpers --no-commit
	forge install a16z/halmos-cheatcodes --no-commit
	forge install rari-capital/solmate --no-commit
	forge install Recon-Fuzz/chimera --no-commit
	forge install crytic/properties --no-commit
	forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v4.9.0 --no-commit
	forge install dapphub/ds-test --no-commit
	forge install ERC4626/erc4626-tests --no-commit

.PHONY: verify-deps
verify-deps:
	@echo "Verifying dependencies..."
	@test -d lib/forge-std || (echo "Missing forge-std" && exit 1)
	@test -d lib/openzeppelin-contracts || (echo "Missing openzeppelin-contracts" && exit 1)
	@test -d lib/setup-helpers || (echo "Missing setup-helpers" && exit 1)
	@test -d lib/halmos-cheatcodes || (echo "Missing halmos-cheatcodes" && exit 1)
	@test -d lib/solmate || (echo "Missing solmate" && exit 1)
	@test -d lib/chimera || (echo "Missing chimera" && exit 1)
	@test -d lib/ds-test || (echo "Missing ds-test" && exit 1)
	@test -d lib/openzeppelin-contracts-upgradeable || (echo "Missing openzeppelin-upgradeable" && exit 1)
	@echo "All dependencies present"

.PHONY: clean-deps
clean-deps:
	rm -rf lib/
	forge clean