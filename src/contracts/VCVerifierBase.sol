// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract VCVerifierBaseContract {
    // Internal function that cannot be modified in the derived contract
    function verify() public {
        bool testResult = true;

        // If verification is successful, call the postVerification() function
        if (testResult) {
            _postVerification(msg.sender);
        }
    }

    // Abstract function that must be defined in the derived contract
    // This will be executed after the verification is successful.
    function _postVerification(address _userAddress) internal virtual;
}
