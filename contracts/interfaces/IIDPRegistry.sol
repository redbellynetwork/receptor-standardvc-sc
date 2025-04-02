// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

interface IIDPRegistry {
    struct Proof {
        string proofType;
        string publicKey;
    }

    struct IDPInformationIO {
        string name;
        string issuerDid;
        string url;
        address publicAddress;
        Proof[] proofs;
    }

    function getByIssuerDid(string memory issuerDid) external view returns (IDPInformationIO memory);
}
