import { expect } from "chai";
import { ethers } from "hardhat";

describe("HelloWorldContract", function () {
  it("Should return the correct greeting", async function () {
    const HelloWorld = await ethers.getContractFactory("HelloWorldContract");
    const helloWorld = await HelloWorld.deploy();

    expect(await helloWorld.greet()).to.equal("Hello, World!");
  });
});
