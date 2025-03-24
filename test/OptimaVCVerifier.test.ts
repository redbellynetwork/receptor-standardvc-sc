import { expect } from "chai";
import { ethers } from "hardhat";

const credentialType = "OptimaV1Credential";

// test setup fixture
async function deployOptimaVCVerifierFixture() {
  const signer = await ethers.provider.getSigner();
  const signerAddress = await signer.getAddress();

  const JsonFormatter = await ethers.getContractFactory("JsonFormatter", signer);
  const jsonFormatter = await JsonFormatter.deploy();
  const jsonFormatterAddress = await jsonFormatter.getAddress();

  const OptimaVCVerifier = await ethers.getContractFactory("OptimaVCVerifier", {
    libraries: { JsonFormatter: jsonFormatterAddress },
    signer,
  });
  const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);

  // Wait for deployment to finish
  await optimaVCVerifier.waitForDeployment();
  return {
    signer,
    optimaVCVerifier,
    signerAddress,
  };
}

describe("OptimaVCVerifier", function () {
  it("Should set the verification status to true is when verified successfully", async function () {
    const { optimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      name: "abc",
      type: ["OptimaV1Credential", "VerifiableCredential"],
    };

    console.log(await optimaVCVerifier.getAddress());
    console.log(await optimaVCVerifier.credentialType());
    console.log(await optimaVCVerifier.abc());
    console.log(await optimaVCVerifier.len1());
    console.log(await optimaVCVerifier.len2());

    const stringVc = JSON.stringify(vc);

    await optimaVCVerifier.connect(signer).verifyCredential(stringVc);

    // await expect(optimaVCVerifier.connect(signer).verifyCredential(stringVc))
    //   .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
    //   .withArgs("Value is larger than string");

    console.log(await optimaVCVerifier.verificationStatus(signerAddress));
    console.log(await optimaVCVerifier.credentialType());
    console.log(await optimaVCVerifier.abc());
    console.log(await optimaVCVerifier.len1());
    console.log(await optimaVCVerifier.len2());
  });

  it("Should set the credentialType after deployment", async function () {
    const { optimaVCVerifier } = await deployOptimaVCVerifierFixture();
    expect(await optimaVCVerifier.credentialType()).to.equal(credentialType);
  });
});
