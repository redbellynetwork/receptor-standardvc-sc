// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {JsonFormatter} from "../libraries/JsonFormatter.sol";
import {Base58} from "../libraries/Base58.sol";
import {IIDPRegistry} from "../interfaces/IIDPRegistry.sol";
import {IBootstrapContractsRegistry} from "@redbellynetwork/bootstrap-contracts/src/contracts/interfaces/IBootstrapContractsRegistry.sol";

abstract contract VCVerifierBaseContract {
    /// @dev - The type of credential(schema) to verify
    string public credentialType;

    /// @dev - Bootstrap Registry Contract Address
    address private constant bootstrapContractsRegistryAddress = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

    error InvalidData(string);
    error InvalidProof(string);

    /**
     * @dev Constructor to set the VCVerifierBaseContract
     * @param _credentialType The type of the credential(schema)
     */
    constructor(string memory _credentialType) {
        credentialType = _credentialType;
    }

    /**
     * @dev Internal function that cannot be modified in the derived contract
     * @param _issuerDid ID of the issuer who've issued the credentials.
     * @param _vc credential issued by issuer without proof
     * @param _proofSignature proof of the credentials issued.
     */
    function verifyCredential(string memory _issuerDid, string memory _vc, string memory _proofSignature) public {
        // Fetching type field(array of schemas) from the credential
        string memory typesInCredential = _parseJson("type", _vc);

        // Checking if the credential type(schema) is present in the type field
        bool isExist = _contains(typesInCredential, credentialType);

        if (!isExist) {
            revert InvalidData("Credential type not exist");
        }

        string memory proofType = _parseJson("type", _proofSignature);
        string memory publicKey = getProofPublicKey(proofType, _issuerDid);

        // check the vc has not been modified by signature
        string memory proofValue = _parseJson("proofValue", _proofSignature);

        // Remove the 'z' prefix from proofValue before decoding
        if (bytes(proofValue)[0] == "z") {
            proofValue = _sliceString(proofValue, 1, bytes(proofValue).length);
        }

        bytes memory decodedProofValue = Base58.decodeFromString(proofValue);
        bool signatureCheck = _verifyED25519(_vc, decodedProofValue, bytes32(JsonFormatter.base64ToBytes(publicKey)));
        if (!signatureCheck) {
            revert InvalidData("Signature verification failed");
        }

        // If verification is successful, call the postVerification() function
        _postVerification(msg.sender);
    }

    /**
     * @dev Abstract function that will be executed after the verification is successful.
     * @param _userAddress address of the user that called the verifyCredential function
     */
    function _postVerification(address _userAddress) internal virtual;

    /**
     * @dev Checks if a given value exists in a comma-separated string.
     * @param _str The string to check.
     * @param _value The value to search for.
     * @return true if the value exists in the string, false otherwise.
     */
    function _contains(string memory _str, string memory _value) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory valueBytes = bytes(_value);

        // Ensure that strBytes is large enough to fit valueBytes
        if (strBytes.length < valueBytes.length) {
            revert InvalidData("Credential type not exist");
        }

        // Loop through the string to see if the value exists
        for (uint256 i = 0; i <= strBytes.length - valueBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < valueBytes.length; j++) {
                if (strBytes[i + j] != valueBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Parses the JSON content at the specified path.
     * @param _path The JSON path string.
     * @param _content The content string.
     * @return The parsed string value at the specified path.
     */
    function _parseJson(string memory _path, string memory _content) internal returns (string memory) {
        bool callresult = false;

        // Format the JSON path request
        bytes memory requestData = JsonFormatter.formatJsonPathRequest(_path, _content);

        // Create a new bytes array for the result
        bytes memory ret = new bytes(requestData.length);

        assembly {
            let len := mload(requestData)

            // Call precompile contract with json parser
            callresult := call(gas(), 101, 0, add(requestData, 0x20), len, add(ret, 0x20), len)

            // Check the result of the call
            switch callresult
            case 0 {
                revert(0, 0)
            }
        }

        // Trim any empty characters from the result and return
        return JsonFormatter.trimEmpty(string(ret));
    }

    /**
     * @dev Fetch the public key of issuer who issued credential
     * @param _proofType The type of proof in credential
     * @param _issuerDid ID of the issuer who've issued the credentials.
     * @return The public key string value
     */
    function getProofPublicKey(
        string memory _proofType,
        string memory _issuerDid
    ) internal view virtual returns (string memory) {
        IBootstrapContractsRegistry bootstrapContractsRegistry = IBootstrapContractsRegistry(
            bootstrapContractsRegistryAddress
        );

        IIDPRegistry.IDPInformationIO memory idpInfo = IIDPRegistry(
            bootstrapContractsRegistry.getContractAddress("idpregistry")
        ).getByIssuerDid(_issuerDid);

        IIDPRegistry.Proof[] memory proofs = idpInfo.proofs;
        for (uint256 i = 0; i < proofs.length; i++) {
            if (keccak256(abi.encodePacked(proofs[i].proofType)) == keccak256(abi.encodePacked(_proofType))) {
                return proofs[i].publicKey;
            }
        }
        revert InvalidProof("proof type doesn't exists");
    }

    /**
     * @dev Slices a given string from a start index to an end index.
     * @param _str The original string to be sliced.
     * @param _startIndex The index at which the slicing starts (inclusive).
     * @param _endIndex The index at which the slicing ends (exclusive).
     * @return A new string that contains the sliced portion of the original string.
     */
    function _sliceString(
        string memory _str,
        uint256 _startIndex,
        uint256 _endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(_endIndex - _startIndex);
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Verifies the ED25519 signature of a proofvalue using a provided VC and IDP public key.
     * @param _vc The VC (Verifiable Credential) string.
     * @param _proofvalue string.
     * @param _idpPublicKey public key of Issuer
     * @return A boolean indicating whether the signature is valid or not.
     */
    function _verifyED25519(
        string memory _vc,
        bytes memory _proofvalue,
        bytes32 _idpPublicKey
    ) internal returns (bool) {
        bool callresult = false;

        // Create a new bytes array for the hash
        bytes memory hash = new bytes(32);

        assembly {
            let len := mload(_vc)

            // Call precompile contract to calculate the hash
            callresult := call(gas(), 2, 0, add(_vc, 0x20), len, add(hash, 0x20), 32)

            // Check the result of the call
            switch callresult
            case 0 {
                revert(0, 0)
            }
        }

        // Encode the request by concatenating the hash and other data
        bytes memory requestData = abi.encodePacked(hash, abi.encodePacked(_idpPublicKey, _proofvalue));

        // Create a new bytes array for the result
        bytes memory result = new bytes(32);

        assembly {
            let len := mload(requestData)

            // Call external contract or function to validate the signature
            callresult := call(gas(), 102, 0, add(requestData, 0x20), len, add(result, 0x20), 32)

            // Check the result of the call
            switch callresult
            case 0 {
                revert(0, 0)
            }
        }

        // Iterate through the result bytes and check if any non-zero byte is found
        for (uint256 i = 0; i < result.length; i++) {
            if (result[i] != 0x00) {
                return true;
            }
        }

        // If no non-zero byte is found, return false
        return false;
    }
}
