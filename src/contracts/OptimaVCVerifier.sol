// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {VCVerifierBaseContract} from "./VCVerifierBase.sol";

contract OptimaVCVerifier is VCVerifierBaseContract {
    // Mapping to store verification status of each user
    mapping(address => bool) public verificationStatus;

    // This function will be called automatically from the verify() function of VCVerifierBase
    function _postVerification(address _userAddress) internal override {
        verificationStatus[_userAddress] = true;
    }
}
