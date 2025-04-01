// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

library JsonFormatter {
    error InvalidData(string);
    /**
     * @dev Formats a JSON path request by combining the path and content strings.
     * @param path The JSON path string.
     * @param content The content string.
     * @return The formatted bytes array representing the JSON path request.
     */
    function formatJsonPathRequest(string memory path, string memory content) external pure returns (bytes memory) {
        // Convert path and content strings to bytes
        bytes memory _path = bytes(path);
        bytes memory _content = bytes(content);

        // Create a new bytes array with the calculated length
        bytes memory result = new bytes(_path.length + _content.length + 4);

        uint256 index = 0;

        result[index++] = "(";

        // Copy path bytes to the result
        for (uint256 i = 0; i < _path.length; i++) {
            result[index++] = _path[i];
        }

        result[index++] = ")";

        result[index++] = "(";

        // Copy content bytes to the result
        for (uint256 i = 0; i < _content.length; i++) {
            result[index++] = _content[i];
        }

        result[index++] = ")";

        return result;
    }

    /// @dev Removes trailing empty characters from a string.
    /// @param str The input string to be trimmed.
    /// @return The trimmed string.
    function trimEmpty(string memory str) external pure returns (string memory) {
        // Convert the input string to bytes for manipulation
        bytes memory strBytes = bytes(str);

        // Get the length of the input string
        uint256 length = strBytes.length;

        // Initialize the index to the length of the string
        uint256 index = length;

        // Iterate backwards to find the first non-empty character
        while (index > 0 && (strBytes[index - 1] == 0x00)) {
            index--;
        }

        // Create a new bytes array with the trimmed length
        bytes memory trimmedBytes = new bytes(index);

        // Copy non-empty characters to the trimmed bytes array
        for (uint256 i = 0; i < index; i++) {
            trimmedBytes[i] = strBytes[i];
        }

        // Convert the trimmed bytes back to a string and return
        return string(trimmedBytes);
    }

    /**
     * @dev Converts a base64 encoded string to bytes.
     * @param base64String The base64 encoded string to be converted.
     * @return The resulting bytes array decoded from the base64 string.
     */
    function base64ToBytes(string memory base64String) external pure returns (bytes memory) {
        // Base64 character set
        bytes memory characters = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");

        // Remove any padding characters at the end of the base64 string
        uint256 padding = 0;
        uint256 length = bytes(base64String).length;

        if (length == 0) return new bytes(0);
        if (length % 4 != 0) {
            revert InvalidData("Invalid Base64 value");
        }

        if (length > 0 && bytes(base64String)[length - 1] == "=") {
            padding = 1;
            if (length > 1 && bytes(base64String)[length - 2] == "=") {
                padding = 2;
            }
        }

        // Calculate the length of the resulting byte array
        uint256 byteLength = (length * 3) / 4 - padding;

        // Create a new byte array with the calculated length
        bytes memory byteArray = new bytes(byteLength);

        // Perform the Base64 decoding
        uint256 index = 0;
        for (uint256 i = 0; i < length; i += 4) {
            uint256 c0 = base64CharIndex(characters, bytes(base64String)[i]);
            uint256 c1 = base64CharIndex(characters, bytes(base64String)[i + 1]);
            uint256 c2 = base64CharIndex(characters, bytes(base64String)[i + 2]);
            uint256 c3 = base64CharIndex(characters, bytes(base64String)[i + 3]);

            byteArray[index] = bytes1(uint8((c0 << 2) | (c1 >> 4)));
            if (index + 1 < byteLength) {
                byteArray[index + 1] = bytes1(uint8((c1 << 4) | (c2 >> 2)));
            }
            if (index + 2 < byteLength) {
                byteArray[index + 2] = bytes1(uint8((c2 << 6) | c3));
            }
            index += 3;
        }

        return byteArray;
    }

    /**
     * @dev Internal function to get the index of a character in the base64 character set.
     * @param characters The base64 character set.
     * @param character The character to find the index of.
     * @return The index of the character in the base64 character set.
     */
    function base64CharIndex(bytes memory characters, bytes1 character) internal pure returns (uint256) {
        for (uint256 i = 0; i < characters.length; i++) {
            if (characters[i] == character) {
                return i;
            }
        }

        // Special case for padding character "="
        if (character == bytes1("=")) {
            return 0;
        }

        revert InvalidData("Invalid Base64 value");
    }
}
