# Configuration
PROJECT := malo-labs
CONTAINER_NAME := ${PROJECT}-contracts
VENV_DIR := .venv
BIN_DIR := ./bin

# Dependency Versions
FOUNDRY_VERSION := nightly
SOLMATE_VERSION := v6
OPENZEPPELIN_VERSION := v5.0.1

# Path Configuration
REMAPPINGS := \
    @rari-capital/solmate/=lib/solmate/src/ \
    @openzeppelin/=lib/openzeppelin-contracts/ \
    @recon/=lib/setup-helpers/src/ \
    forge-std/=lib/forge-std/src/

# Testing Configuration
ECHIDNA_CONFIG := ./test/echidna/echidna_config.yaml
CORPUS_DIR := ./test/echidna/_corpus
MEDUSA_CONFIG := ./test/medusa/medusa.json

.PHONY: help all build test clean deps install-tools verify \
        gas coverage echidna halmos medusa docker

.DEFAULT_GOAL := help

# Help system
help:
	@echo "Malo Labs Contract Management System"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Core Targets:"
	@echo "  all         Clean and rebuild project"
	@echo "  build       Compile contracts"
	@echo "  test        Run all tests"
	@echo "  clean       Remove build artifacts"
	@echo ""
	@echo "Dependency Management:"
	@echo "  deps        Install all dependencies"
	@echo "  verify      Verify dependency integrity"
	@echo ""
	@echo "Analysis & Security:"
	@echo "  gas         Generate gas reports"
	@echo "  coverage    Generate coverage reports"
	@echo "  echidna     Run Echidna property testing"
	@echo "  halmos      Run symbolic execution"
	@echo "  medusa      Run fuzz testing"
	@echo ""
	@echo "Infrastructure:"
	@echo "  docker      Build Docker container"
	@echo "  install-tools Install development tools"

# Core targets
all: clean build

.PHONY: install-deps
install-deps:
	./bin/install-deps.sh

build:
	@forge build --remappings ${REMAPPINGS}
	@echo "✅ Build complete"

test:
	@forge test --remappings ${REMAPPINGS}
	@echo "✅ Tests completed"

clean: clean-echidna clean-forge
	@rm -rf ./coverage ./cache ./out
	@echo "✅ Clean complete"

# Dependency management
deps: install-system install-foundry install-deps create-links

install-system:
	@echo "🔧 Installing system dependencies..."
	@sudo apt-get update -qq && sudo apt-get install -y \
		build-essential libssl-dev pkg-config \
		clang cmake librocksdb-dev curl git jq

install-foundry:
	@echo "🛠️ Installing Foundry..."
	@curl -L https://foundry.paradigm.xyz | bash
	@. ${HOME}/.bashrc
	@${HOME}/.foundry/bin/foundryup -v ${FOUNDRY_VERSION}


create-links:
	@echo "🔗 Creating legacy symlinks..."
	@mkdir -p lib/rari-capital
	@ln -sf ${PWD}/lib/solmate lib/rari-capital/solmate 2>/dev/null || true

verify:
	@echo "🔍 Verifying dependencies..."
	@test -d lib/forge-std || (echo "❌ Missing forge-std"; exit 1)
	@test -d lib/openzeppelin-contracts || (echo "❌ Missing OpenZeppelin"; exit 1)
	@test -d lib/solmate || (echo "❌ Missing Solmate"; exit 1)
	@echo "✅ All dependencies verified"

# Analysis targets
gas:
	@echo "⛽ Generating gas report..."
	@forge test --gas-report --remappings ${REMAPPINGS}

coverage:
	@echo "📊 Generating coverage report..."
	@forge coverage --report lcov
	@genhtml lcov.info -o coverage
	@echo "📈 Coverage report generated at coverage/index.html"

# Security testing
echidna: ensure-dirs
	@echo "🦔 Running Echidna tests..."
	@echidna ./test/echidna/Setup.sol \
		--contract Setup \
		--config ${ECHIDNA_CONFIG} \
		--corpus-dir ${CORPUS_DIR} \
		--solc-remappings ${REMAPPINGS}

halmos:
	@echo "🔍 Running symbolic analysis..."
	@halmos --solver-timeout-assertion 10000 \
		--solc-remappings ${REMAPPINGS}

medusa:
	@echo "🌀 Running fuzz testing..."
	@medusa fuzz --config ${MEDUSA_CONFIG} \
		--solc-remappings ${REMAPPINGS}

# Infrastructure
docker:
	@echo "🐳 Building Docker container..."
	@docker build --progress=plain -t ${CONTAINER_NAME} .

install-tools:
	@echo "🧰 Installing development tools..."
	@python3 -m venv ${VENV_DIR}
	@. ${VENV_DIR}/bin/activate && pip install echidna-parade halmos
	@echo "✅ Tools installed in ${VENV_DIR}"

# Helper targets
ensure-dirs:
	@mkdir -p ${CORPUS_DIR}
	@mkdir -p test/echidna/_exploration
	@mkdir -p test/echidna/_assertion

clean-echidna:
	@rm -rf ${CORPUS_DIR} test/echidna/_exploration test/echidna/_assertion

clean-forge:
	@forge clean