// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

library TimeParserUtils {
    string internal constant RFC3339NANO = "2006-01-02T15:04:05.999999999Z07:00";

    error InvalidString(string);
    error InvalidDateTime(string);
    /**
     * @dev Formats a Test Parser request by combining the timestamp and format strings.
     * @param timestampString The timestamp in string.
     * @param format Format of timestamp.
     * @return The formatted bytes array representing the Time Parser request.
     */
    function formatTimeParserRequest(
        string memory timestampString,
        string memory format
    ) external pure returns (bytes memory) {
        if (bytes(timestampString).length <= 0) {
            revert InvalidDateTime("timestampString must not be empty");
        }
        if (bytes(format).length <= 0) {
            revert InvalidDateTime("format must not be empty");
        }
        // Convert path and content strings to bytes
        bytes memory path = bytes(timestampString);
        bytes memory content = bytes(format);

        // Create a new bytes array with the calculated length
        bytes memory result = new bytes(path.length + content.length + 1);

        uint256 index = 0;

        // Copy path bytes to the result
        for (uint256 i = 0; i < path.length; i++) {
            result[index++] = path[i];
        }

        result[index++] = "|";

        // Copy content bytes to the result
        for (uint256 i = 0; i < content.length; i++) {
            result[index++] = content[i];
        }

        return result;
    }

    function stringToUint(string memory numString) public pure returns (uint256) {
        if (bytes(numString).length <= 0) {
            revert InvalidString("numString must not be empty");
        }
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10 ** (exp - 1)));
        }
        return val;
    }
}
