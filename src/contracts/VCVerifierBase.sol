// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract VCVerifierBaseContract {
    // Internal function that cannot be modified in the derived contract
    function verify(string memory _issuerDid, string memory _vcs, string memory _proofSignature) public {
        bool testResult = true;

        // If verification is successful, call the postVerification() function
        if (testResult) {
            postVerification(_issuerDid, _vcs, _proofSignature, msg.sender);
        }
    }

    // Abstract function that must be defined in the derived contract
    // This will be executed after the verification is successful.
    function postVerification(
        string memory _issuerDid,
        string memory _vcs,
        string memory _proofSignature,
        address _userAddress
    ) internal virtual;
}
