// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VCVerifierBaseContract} from "./VCVerifierBase.sol";

contract OptimaVCVerifier is VCVerifierBaseContract {
    // Mapping to store verification status of each user
    mapping(address => bool) public verificationStatus;

    // This function will be called automatically from the verify() function of VCVerifierBase
    function postVerification(
        string memory _issuerDid,
        string memory _vcs,
        string memory _proofSignature,
        address _userAddress
    ) internal override {
        verificationStatus[_userAddress] = true;
    }
}
