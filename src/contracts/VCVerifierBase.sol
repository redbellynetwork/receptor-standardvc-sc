// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {JsonFormatter} from "../libraries/JsonFormatter.sol";

abstract contract VCVerifierBaseContract {
    /// @dev - The type of credential(schema) to verify
    string public credentialType;

    error InvalidData(string);

    /**
     * @dev Constructor to set the VCVerifierBaseContract
     * @param _credentialType The type of the credential(schema)
     */
    constructor(string memory _credentialType) {
        credentialType = _credentialType;
    }

    /**
     * @dev Internal function that cannot be modified in the derived contract
     * @param _vc credential issued by issuer without proof
     */
    function verifyCredential(string memory _vc) public {
        // Fetching type field(array of schemas) from the credential
        string memory typesInCredential = _parseJson("type", _vc);

        // Checking if the credential type(schema) is present in the type field
        bool isExist = _contains(typesInCredential, credentialType);

        if (!isExist) {
            revert InvalidData("Credential type not exist");
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
     * @param str The string to check.
     * @param value The value to search for.
     * @return true if the value exists in the string, false otherwise.
     */
    function _contains(string memory str, string memory value) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory valueBytes = bytes(value);

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
}
