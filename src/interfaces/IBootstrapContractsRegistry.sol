// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface IBootstrapContractsRegistry {
    function register(string calldata name, address contractAddress) external returns (bool);

    function getContractAddress(string memory contractName) external view returns (address);
}
