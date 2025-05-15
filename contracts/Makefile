.PHONY: test clean clean-echidna clean-forge clean-tools build gas echidna echidna-assert echidna-explore echidna-crytic echidna-config ensure-dirs echidna-parade clean-parade echidna-parade-justlen analyze-parade-failures cleanup-interrupted halmos medusa install-hooks install-echidna install-halmos install-tools deps verify-deps compile bindings gha docker compile-in-docker bindings-in-docker all-in-docker gha-docker storage-report fix-typos fmt update-deps

# Original structure with critical fixes
test:
	forge test --remappings @rari-capital/solmate/=lib/solmate/src/ @recon/=lib/setup-helpers/src/

clean: clean-echidna clean-forge clean-tools
	rm -rf ./coverage
	rm -rf ./test/echidna/_corpus

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
	forge build --remappings @rari-capital/solmate/=lib/solmate/src/ @recon/=lib/setup-helpers/src/
	@echo "Build complete"

gas:
	WRITE_GAS_REPORT=true forge test --mp test/gas/ --gas-report/*.g.sol --isolate --remappings @rari-capital/solmate/=lib/solmate/src/
	forge coverage --report gas --report-path coverage/gas-report --report-format html

# Echidna targets with path fixes
echidna: ensure-dirs
	echidna ./test/echidna/Setup.sol \
		--contract Setup \
		--config test/echidna/echidna_config.yaml \
		--corpus-dir test/echidna/_corpus \
		--solc-remappings @rari-capital/solmate/=lib/solmate/src/

echidna-assert: ensure-dirs
	echidna ./test/echidna/Setup.sol \
		--contract Setup \
		--test-mode assertion \
		--config test/echidna/echidna_config.yaml \
		--solc-remappings @rari-capital/solmate/=lib/solmate/src/

# Preserved original complex targets with fixes
ensure-dirs:
	mkdir -p test/echidna/_corpus
	mkdir -p test/echidna/_exploration
	mkdir -p test/echidna/_assertion

echidna-parade: ensure-dirs
	PATH="$$HOME/.foundry/bin:$$PATH" echidna-parade \
		--name malo-labs \
		--contract Setup \
		--config test/echidna/echidna_config.yaml \
		--corpus_dir test/echidna/_corpus \
		--ncores 16 \
		./test/echidna/Setup.sol

# Dependency installation with critical fixes
install-deps:
	curl -L https://foundry.paradigm.xyz | bash
	source $$HOME/.bashrc
	foundryup
	forge install transmissions11/solmate@v6 --no-commit
	forge install recon-fuzz/setup-helpers --no-commit
	ln -sf $$(pwd)/lib/solmate lib/rari-capital/solmate 2>/dev/null || true

# Preserved Docker target
docker:
	docker build --progress=plain -t malo-labs-contracts .

# Preserved complex parade targets
echidna-parade-justlen: ensure-dirs
	echidna-parade ./parade/justlen.sol \
		--name justlen \
		--contract TEST \
		--config parade/justlen.yaml \
		--solc-remappings @rari-capital/solmate/=lib/solmate/src/

# Preserved analysis targets
analyze-parade-failures:
	@if [ -d justlen ]; then \
	  find justlen -name "*.txt" -exec grep -l "FAILED" {} \; | while read f; do \
		echo "\nFailures in $$f:"; \
		grep -A 5 "FAILED" "$$f"; \
	  done; \
	fi

# Preserved symbolic testing
halmos:
	halmos --solver-timeout-assertion 10000 --solc-remappings @rari-capital/solmate/=lib/solmate/src/

# Preserved formatting targets
fmt:
	forge fmt