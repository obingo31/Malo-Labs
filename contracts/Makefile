.PHONY: test clean clean-echidna clean-forge clean-tools

# This Makefile is used to run tests and coverage for the contracts in the Malo-Labs repository.

clean: clean-echidna clean-forge clean-tools
	rm -rf ./coverage

clean-echidna:
	rm -rf ./test/echidna/_corpus
	rm -rf ./test/echidna/_exploration
	rm -rf ./test/echidna/_assertion
	rm -rf ./test/echidna/_call_sequences

clean-forge:
	forge clean

clean-tools:
	rm -rf .venv

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
	echidna ./test/echidna/Setup.sol \
		--contract Setup \
		--test-mode assertion \
		--config $(ECHIDNA_CONFIG) \
		--corpus-dir $(CORPUS_DIR)

echidna-explore:
	echidna ./test/echidna/Setup.sol \
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

# Ensure test directories exist
.PHONY: ensure-dirs
ensure-dirs:
	mkdir -p test/echidna/_corpus
	mkdir -p test/echidna/_exploration
	mkdir -p test/echidna/_assertion

# Echidna Parade Configuration
ECHIDNA_PARADE_CONFIG := ./test/echidna/echidna_config.yaml
ECHIDNA_PARADE_CONTRACT := Setup
ECHIDNA_PARADE_CORES := 16
ECHIDNA_PARADE_TIMEOUT := 3600
ECHIDNA_PARADE_GEN_TIME := 300

.PHONY: echidna-parade
echidna-parade: ensure-dirs
	PATH="$(INSTALL_DIR):$$PATH" . $(VENV_DIR)/bin/activate && echidna-parade \
		--name malo-labs \
		--contract $(ECHIDNA_PARADE_CONTRACT) \
		--config $(ECHIDNA_CONFIG) \
		--corpus_dir $(CORPUS_DIR) \
		--ncores $(ECHIDNA_PARADE_CORES) \
		--timeout $(ECHIDNA_PARADE_TIMEOUT) \
		--gen_time $(ECHIDNA_PARADE_GEN_TIME) \
		./test/echidna/Setup.sol

# Clean up previous parade runs
.PHONY: clean-parade
clean-parade:
	rm -rf justlen/

# Echidna Parade Just Length Configuration
JUSTLEN_CONFIG := ./parade/justlen.yaml
JUSTLEN_CONTRACT := TEST
JUSTLEN_TIMEOUT := 120
JUSTLEN_GEN_TIME := 30
JUSTLEN_CORES := 8
JUSTLEN_MIN_SEQ := 27  # Based on smallest successful sequence length
JUSTLEN_MAX_SEQ := 290 # Based on largest attempted sequence length
JUSTLEN_DICT_FREQ := 0.4

# Add resume option, defaulting to empty
RESUME ?= 

# Cleanup and interrupt handling
.PHONY: cleanup-interrupted
cleanup-interrupted:
	@echo "Cleaning up interrupted parade run..."
	-@pkill -f echidna-test || true
	-@find justlen -name "gen.*" -type d -mmin -2 -exec rm -rf {} \; || true
	@echo "Cleanup complete"

# Update echidna-parade-justlen to handle interrupts
.PHONY: echidna-parade-justlen
echidna-parade-justlen: ensure-dirs $(if $(RESUME),,clean-parade)
	echidna-parade \
		./parade/justlen.sol \
		--name justlen \
		--contract $(JUSTLEN_CONTRACT) \
		--config $(JUSTLEN_CONFIG) \
		--timeout $(JUSTLEN_TIMEOUT) \
		--gen_time $(JUSTLEN_GEN_TIME) \
		--ncores $(JUSTLEN_CORES) \
		--minseqLen $(JUSTLEN_MIN_SEQ) \
		--maxseqLen $(JUSTLEN_MAX_SEQ) \
		--PdefaultDict $(JUSTLEN_DICT_FREQ) \
		$(if $(RESUME),--resume $(RESUME),) \
		--always "TEST.turn_on_length_checking()" \
				"TEST.push_1()" \
				"TEST.plus5()" \
				"TEST.test_long_64()" \
				"TEST.test_long_128()" \
		--no-wait || make cleanup-interrupted

# Add target for analyzing failures
.PHONY: analyze-parade-failures
analyze-parade-failures:
	@echo "Analyzing Echidna Parade failures..."
	@if [ -d justlen ]; then \
	  find justlen -name "*.txt" -exec grep -l "FAILED" {} \; | while read f; do \
		echo "\nFailures in $$f:"; \
		grep -A 5 "FAILED" "$$f"; \
	  done; \
	else \
	  echo "No generation directory (justlen) found."; \
	fi

# Symbolic Testing
halmos:
	halmos --solver-timeout-assertion 10000

# Fuzz Testing
medusa:
	medusa fuzz --config ./medusa.json

CONTAINER_NAME = Malo-Labs-contracts

VENV_DIR := .venv

# Installation paths
INSTALL_DIR := $(HOME)/.local/bin

.PHONY: install-hooks
install-hooks:
	cp bin/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

.PHONY: install-echidna
install-echidna:
	# Install echidna using Docker
	docker pull ghcr.io/crytic/echidna/echidna:latest
	# Create wrapper script
	@echo '#!/bin/bash' > $(INSTALL_DIR)/echidna-test
	@echo 'docker run --rm -v "$$PWD:/code" -w /code ghcr.io/crytic/echidna/echidna:latest "$$@"' >> $(INSTALL_DIR)/echidna-test
	@chmod +x $(INSTALL_DIR)/echidna-test
	@echo "Echidna installed to $(INSTALL_DIR)/echidna-test"

.PHONY: install-halmos
install-halmos:
	pip3 install halmos --user

.PHONY: install-tools
install-tools: install-echidna install-halmos
	python3 -m venv $(VENV_DIR)
	. $(VENV_DIR)/bin/activate && pip3 install echidna-parade
	@echo "Tools installed in virtual environment at $(VENV_DIR)"

.PHONY: install-deps
install-deps:
	./bin/install-deps.sh
	$(MAKE) install-tools

# Dependencies management
.PHONY: deps
deps: clean-deps install-all-deps verify-deps
	@echo "Dependencies installed and verified"

.PHONY: clean-deps
clean-deps:
	rm -rf lib/
	forge clean

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

.PHONY: compile
compile:
	forge build

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