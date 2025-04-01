// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

/// @title String to Address Parser
/// @notice Use this library to convert string into an address type
library StringToAddress {
    function stringToAddress(string memory userAddress) external pure returns (address) {
        string memory cleanAddress = remove0xPrefix(userAddress);
        bytes20 addressBytes = parseHexStringToBytes20(cleanAddress);
        return address(addressBytes);
    }

    function remove0xPrefix(string memory hexString) internal pure returns (string memory) {
        if (
            bytes(hexString).length >= 2 &&
            bytes(hexString)[0] == "0" &&
            (bytes(hexString)[1] == "x" || bytes(hexString)[1] == "X")
        ) {
            return substring(hexString, 2, bytes(hexString).length);
        }
        return hexString;
    }

    function substring(string memory str, uint256 start, uint256 end) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }

    function parseHexStringToBytes20(string memory hexString) internal pure returns (bytes20) {
        bytes memory bytesString = bytes(hexString);
        uint160 parsedBytes = 0;
        for (uint256 i = 0; i < bytesString.length; i += 2) {
            parsedBytes *= 256;
            uint8 byteValue = parseByteToUint8(bytesString[i]);
            byteValue *= 16;
            byteValue += parseByteToUint8(bytesString[i + 1]);
            parsedBytes += byteValue;
        }
        return bytes20(parsedBytes);
    }

    function parseByteToUint8(bytes1 data) internal pure returns (uint8) {
        if (uint8(data) >= 48 && uint8(data) <= 57) {
            return uint8(data) - 48;
        } else if (uint8(data) >= 65 && uint8(data) <= 70) {
            return uint8(data) - 55;
        } else if (uint8(data) >= 97 && uint8(data) <= 102) {
            return uint8(data) - 87;
        } else {
            revert(string(abi.encodePacked("Invalid byte value: ", data)));
        }
    }
}
