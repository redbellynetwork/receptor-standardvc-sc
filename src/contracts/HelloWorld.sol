// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IHelloWorld} from "../interfaces/IHelloWorld.sol";

contract HelloWorldContract is IHelloWorld {
    function greet() external pure override returns (string memory) {
        return "Hello, World!";
    }
}
