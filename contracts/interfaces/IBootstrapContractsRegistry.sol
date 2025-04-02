// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface IBootstrapContractsRegistry {
    function getContractAddress(string memory contractName) external view returns (address);
}
