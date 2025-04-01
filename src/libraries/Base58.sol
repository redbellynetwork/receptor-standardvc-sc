// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

/**
 * @title Base58
 * @author storyicon@foxmail.com
 * @notice This algorithm was migrated from github.com/mr-tron/base58 to solidity.
 * Note that it is not yet optimized for gas, so it is recommended to use it only in the view/pure function.
 */
library Base58 {
    bytes internal constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @notice decode is used to decode the given string in base58 standard.
     * @param data data encoded with base58, passed in as bytes.
     * @return raw data, returned as bytes.
     */
    function decode(bytes memory data) public pure returns (bytes memory) {
        unchecked {
            uint256 zero = 49;
            uint256 b58sz = data.length;
            uint256 zcount = 0;
            for (uint256 i = 0; i < b58sz && uint8(data[i]) == zero; i++) {
                zcount++;
            }
            uint256 t;
            uint256 c;
            bool f;
            bytes memory binu = new bytes(2 * (((b58sz * 8351) / 6115) + 1));
            uint32[] memory outi = new uint32[]((b58sz + 3) / 4);
            for (uint256 i = 0; i < data.length; i++) {
                bytes1 r = data[i];
                (c, f) = indexOf(ALPHABET, r);
                require(f, "invalid base58 digit");
                for (int256 k = int256(outi.length) - 1; k >= 0; k--) {
                    t = uint64(outi[uint256(k)]) * 58 + c;
                    c = t >> 32;
                    outi[uint256(k)] = uint32(t & 0xffffffff);
                }
            }
            uint64 mask = uint64(b58sz % 4) * 8;
            if (mask == 0) {
                mask = 32;
            }
            mask -= 8;
            uint256 outLen = 0;
            for (uint256 j = 0; j < outi.length; j++) {
                while (mask < 32) {
                    binu[outLen] = bytes1(uint8(outi[j] >> mask));
                    outLen++;
                    if (mask < 8) {
                        break;
                    }
                    mask -= 8;
                }
                mask = 24;
            }
            for (uint256 msb = zcount; msb < binu.length; msb++) {
                if (binu[msb] > 0) {
                    return slice(binu, msb - zcount, outLen);
                }
            }
            return slice(binu, 0, outLen);
        }
    }

    /**
     * @notice decode is used to decode the given string in base58 standard.
     * @param data data encoded with base58, passed in as string.
     * @return raw data, returned as bytes.
     */
    function decodeFromString(string memory data) public pure returns (bytes memory) {
        return decode(bytes(data));
    }

    /**
     * @notice slice is used to slice the given byte, returns the bytes in the range of [start_, end_)
     * @param data raw data, passed in as bytes.
     * @param start start index.
     * @param end end index.
     * @return slice data
     */
    function slice(bytes memory data, uint256 start, uint256 end) public pure returns (bytes memory) {
        unchecked {
            bytes memory ret = new bytes(end - start);
            for (uint256 i = 0; i < end - start; i++) {
                ret[i] = data[i + start];
            }
            return ret;
        }
    }

    /**
     * @notice indexOf is used to find where char_ appears in data.
     * @param data raw data, passed in as bytes.
     * @param char target byte.
     * @return index, and whether the search was successful.
     */
    function indexOf(bytes memory data, bytes1 char) public pure returns (uint256, bool) {
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                if (data[i] == char) {
                    return (i, true);
                }
            }
            return (0, false);
        }
    }
}
