#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting Credora Protocol Dev Setup...${NC}"

if curl -s http://127.0.0.1:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' | grep -q "anvil"; then
    echo -e "${GREEN}Anvil is already running.${NC}"
else
    echo -e "${YELLOW}Anvil not found. Starting in background...${NC}"
    anvil --block-time 1 > anvil.log 2>&1 &
    sleep 3
    
    if curl -s http://127.0.0.1:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' | grep -q "anvil"; then
        echo -e "${GREEN}Anvil started successfully (PID: $!).${NC}"
    else
        echo -e "${RED}Error: Failed to start Anvil. Make sure Foundry is installed.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Compiling smart contracts (forge build)...${NC}"
forge build
if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}Deploying contracts to localhost (forge script)...${NC}"
forge script script/DeployCore.s.sol:DeployCore --rpc-url http://127.0.0.1:8545 --broadcast
if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}Updating ABIs for frontend/ and sdk/...${NC}"

mkdir -p frontend/abis
mkdir -p sdk/abis

CONTRACTS=("LendingPool" "DefaultReserveInterestRateStrategy")

for contract in "${CONTRACTS[@]}"; do
    if [ -f "out/${contract}.sol/${contract}.json" ]; then
        jq '.abi' "out/${contract}.sol/${contract}.json" > "frontend/abis/${contract}.abi.json"
        cp "frontend/abis/${contract}.abi.json" "sdk/abis/"
        echo -e "${GREEN}   -> ${contract} ABI copied.${NC}"
    else
        echo -e "${RED}   -> Warning: Artifact for ${contract} not found!${NC}"
    fi
done

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}Setup complete! Contracts deployed to localhost.${NC}"
echo -e "${YELLOW}You can now start the frontend: npm run dev${NC}"
echo -e "${GREEN}====================================================${NC}"