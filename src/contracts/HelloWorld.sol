// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IHelloWorld} from "../interfaces/IHelloWorld.sol";

contract HelloWorldContract is IHelloWorld {
    function greet() external pure override returns (string memory) {
        return "Hello, World!";
    }
}
