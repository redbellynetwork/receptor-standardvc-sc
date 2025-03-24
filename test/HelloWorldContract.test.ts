import { expect } from "chai";
import { ethers } from "hardhat";

describe("HelloWorldContract", function () {
  it("Should return the correct greeting", async function () {
    const signer = await ethers.provider.getSigner();

    const HelloWorld = await ethers.getContractFactory("HelloWorldContract", signer);
    const helloWorld = await HelloWorld.deploy();
    await helloWorld.waitForDeployment();

    expect(await helloWorld.greet()).to.equal("Hello, World!");
  });
});
