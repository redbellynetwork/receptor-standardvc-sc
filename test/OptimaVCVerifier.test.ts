import { expect } from "chai";
import { ethers } from "hardhat";

describe("OptimaVCVerifier", function () {
  it("Should set the verificationStatus to true if verified", async function () {
    const [signer1] = await ethers.getSigners();

    const OptimaVCVerifier = await ethers.getContractFactory("OptimaVCVerifier");
    const optimaVCVerifier = await OptimaVCVerifier.deploy();

    await optimaVCVerifier.connect(signer1).verify();

    expect(await optimaVCVerifier.verificationStatus(signer1)).to.equal(true);
  });
  it("Should not set the verificationStatus to true if not verified", async function () {
    const [signer2] = await ethers.getSigners();

    const OptimaVCVerifier = await ethers.getContractFactory("OptimaVCVerifier");
    const optimaVCVerifier = await OptimaVCVerifier.deploy();

    expect(await optimaVCVerifier.verificationStatus(signer2)).to.equal(false);
  });
});
