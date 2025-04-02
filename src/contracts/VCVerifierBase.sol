// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {JsonFormatter} from "../libraries/JsonFormatter.sol";
import {Base58} from "../libraries/Base58.sol";
import {TimeParserUtils} from "../libraries/TimeParserUtils.sol";
import {StringToAddress} from "../libraries/StringToAddress.sol";
import {IIDPRegistry} from "../interfaces/IIDPRegistry.sol";
import {IBootstrapContractsRegistry} from "../interfaces/IBootstrapContractsRegistry.sol";

abstract contract VCVerifierBaseContract {
    /// @dev - The type of credential(schema) to verify
    string public credentialType;

    /// @dev - Bootstrap Registry Contract Address
    address private constant _BOOTSTRAP_CONTRACTS_REGISTRY_ADDRESS = 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5;

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
     * @param issuerDid ID of the issuer who've issued the credentials.
     * @param vc credential issued by issuer without proof
     * @param proofSignature proof of the credentials issued.
     */
    function verifyCredential(string memory issuerDid, string memory vc, string memory proofSignature) public {
        // Fetching type field(array of schemas) from the credential
        string memory typesInCredential = _parseJson("type", vc);

        // Checking if the credential type(schema) is present in the type field
        bool isExist = _substringExists(typesInCredential, credentialType);

        if (!isExist) {
            revert InvalidData("Credential type not exist");
        }

        // Check the validFrom date is in past
        string memory validFrom = _parseJson("validFrom", vc);
        uint256 validFromUnix = _convertTimestampStringToUnix(validFrom);
        if (validFromUnix >= block.timestamp) {
            revert InvalidData("validFrom date must be in the past");
        }

        // Check the validUntil date is not in past
        string memory validUntil = _parseJson("validUntil", vc);
        uint256 validUntilUnix = _convertTimestampStringToUnix(validUntil);
        if (validUntilUnix < block.timestamp) {
            revert InvalidData("The validUntil date cannot be in the past");
        }

        // Check public address in vcs is same as msg.sender.
        string memory user = _parseJson("credentialSubject.publicAddress", vc);
        if (StringToAddress.stringToAddress(user) != msg.sender) {
            revert InvalidData("CredentialSubject publicAddress and msg.sender doesn't match");
        }

        // Checking the proof signature is valid or not
        string memory proofType = _parseJson("type", proofSignature);
        string memory publicKey = _getProofPublicKey(proofType, issuerDid);

        string memory proofValue = _parseJson("proofValue", proofSignature);

        // Remove the 'z' prefix from proofValue before decoding
        if (bytes(proofValue)[0] == "z") {
            proofValue = _sliceString(proofValue, 1, bytes(proofValue).length);
        }

        bytes memory decodedProofValue = Base58.decodeFromString(proofValue);
        bool signatureCheck = _verifyED25519(vc, decodedProofValue, bytes32(JsonFormatter.base64ToBytes(publicKey)));
        if (!signatureCheck) {
            revert InvalidData("Signature verification failed");
        }

        // If verification is successful, call the postVerification() function
        _postVerification(msg.sender);
    }

    /**
     * @dev Abstract function that will be executed after the verification is successful.
     * @param userAddress address of the user that called the verifyCredential function
     */
    function _postVerification(address userAddress) internal virtual;

    /**
     * @dev Checks if a given searchValue exists as a substring in the main string data.
     * @param mainString The string where we search for the searchValue.
     * @param searchValue The value (substring) we are searching for in the main string data.
     * @return true if the searchValue exists in the mainString, false otherwise.
     */
    function _substringExists(string memory mainString, string memory searchValue) internal pure returns (bool) {
        bytes memory mainStringBytes = bytes(mainString);
        bytes memory searchValueBytes = bytes(searchValue);

        // Ensure that strBytes is large enough to fit valueBytes
        if (mainStringBytes.length < searchValueBytes.length) {
            revert InvalidData("Credential type not exist");
        }

        // Loop through the string to see if the value exists
        for (uint256 i = 0; i <= mainStringBytes.length - searchValueBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < searchValueBytes.length; j++) {
                if (mainStringBytes[i + j] != searchValueBytes[j]) {
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
     * @param path The JSON path string.
     * @param content The content string.
     * @return The parsed string value at the specified path.
     */
    function _parseJson(string memory path, string memory content) internal returns (string memory) {
        bool callresult = false;

        // Format the JSON path request
        bytes memory requestData = JsonFormatter.formatJsonPathRequest(path, content);

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
     * @param proofType The type of proof in credential
     * @param issuerDid ID of the issuer who've issued the credentials.
     * @return The public key string value
     */
    function _getProofPublicKey(
        string memory proofType,
        string memory issuerDid
    ) internal view virtual returns (string memory) {
        IBootstrapContractsRegistry bootstrapContractsRegistry = IBootstrapContractsRegistry(
            _BOOTSTRAP_CONTRACTS_REGISTRY_ADDRESS
        );

        IIDPRegistry.IDPInformationIO memory idpInfo = IIDPRegistry(
            bootstrapContractsRegistry.getContractAddress("idpregistry")
        ).getByIssuerDid(issuerDid);

        IIDPRegistry.Proof[] memory proofs = idpInfo.proofs;
        for (uint256 i = 0; i < proofs.length; i++) {
            if (keccak256(abi.encodePacked(proofs[i].proofType)) == keccak256(abi.encodePacked(proofType))) {
                return proofs[i].publicKey;
            }
        }
        revert InvalidProof("proof type doesn't exists");
    }

    /**
     * @dev Slices a given string from a start index to an end index.
     * @param str The original string to be sliced.
     * @param startIndex The index at which the slicing starts (inclusive).
     * @param endIndex The index at which the slicing ends (exclusive).
     * @return A new string that contains the sliced portion of the original string.
     */
    function _sliceString(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Verifies the ED25519 signature of a proofvalue using a provided VC and IDP public key.
     * @param vc The VC (Verifiable Credential) string.
     * @param proofvalue string.
     * @param idpPublicKey public key of Issuer
     * @return A boolean indicating whether the signature is valid or not.
     */
    function _verifyED25519(string memory vc, bytes memory proofvalue, bytes32 idpPublicKey) internal returns (bool) {
        bool callresult = false;

        // Create a new bytes array for the hash
        bytes memory hash = new bytes(32);

        assembly {
            let len := mload(vc)

            // Call precompile contract to calculate the hash
            callresult := call(gas(), 2, 0, add(vc, 0x20), len, add(hash, 0x20), 32)

            // Check the result of the call
            switch callresult
            case 0 {
                revert(0, 0)
            }
        }

        // Encode the request by concatenating the hash and other data
        bytes memory requestData = abi.encodePacked(hash, abi.encodePacked(idpPublicKey, proofvalue));

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

    /**
     * @dev Converts a timestamp string to a Unix timestamp (seconds since epoch).
     * @param timestampString The string representing the timestamp to be converted.
     * @return A uint256 value representing the Unix timestamp corresponding to the input string.
     */
    function _convertTimestampStringToUnix(string memory timestampString) internal returns (uint256) {
        bool callresult = false;

        // Format the JSON path request
        bytes memory requestData = TimeParserUtils.formatTimeParserRequest(
            timestampString,
            TimeParserUtils.RFC3339NANO
        );

        // Create a new bytes array for the result
        bytes memory ret = new bytes(32);

        assembly {
            let len := mload(requestData)

            // Call precompile contract with json parser
            callresult := call(gas(), 103, 0, add(requestData, 0x20), len, add(ret, 0x20), len)

            // Check the result of the call
            switch callresult
            case 0 {
                revert(0, 0)
            }
        }

        string memory unitTimestampString = JsonFormatter.trimEmpty(string(ret));

        return TimeParserUtils.stringToUint(unitTimestampString);
    }
}
