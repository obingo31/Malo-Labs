#!/bin/bash

# Staker Contract Echidna Test Runner
set -e

echo "🚀 Starting Staker Contract Fuzzing Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configurations
CONFIG_FILE="test/echidna.yaml"
CONTRACT_FILE="test/TestStaker.sol"
CONTRACT_NAME="TestStaker"
CORPUS_DIR="./corpus"

# Create corpus directory
mkdir -p $CORPUS_DIR

echo -e "${YELLOW}📋 Running Property Tests...${NC}"
echidna $CONTRACT_FILE --contract $CONTRACT_NAME --config $CONFIG_FILE --test-mode property

echo -e "${YELLOW}📊 Running with Coverage...${NC}"
echidna $CONTRACT_FILE --contract $CONTRACT_NAME --config $CONFIG_FILE --coverage

echo -e "${YELLOW}🎯 Running Assertion Tests...${NC}"
echidna $CONTRACT_FILE --contract $CONTRACT_NAME --config $CONFIG_FILE --test-mode assertion

echo -e "${YELLOW}💾 Saving Test Corpus...${NC}"
echidna $CONTRACT_FILE --contract $CONTRACT_NAME --config $CONFIG_FILE --corpus-dir $CORPUS_DIR

echo -e "${GREEN}✅ All tests completed!${NC}"
echo -e "${GREEN}📁 Test corpus saved to: $CORPUS_DIR${NC}"

# Generate summary report
echo -e "\n${YELLOW}📈 Test Summary:${NC}"
echo "- Property tests: Completed"
echo "- Coverage analysis: Generated"
echo "- Assertion tests: Completed"
echo "- Corpus generation: Saved"

# Check for any failures
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed successfully!${NC}"
else
    echo -e "\n${RED}❌ Some tests failed. Check output above.${NC}"
    exit 1
fi