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

  return {
    signer,
    OptimaVCVerifier,
    signerAddress,
  };
}

describe("OptimaVCVerifier", function () {
  it("Should set the credentialType after deployment", async function () {
    const { OptimaVCVerifier } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.credentialType()).to.equal(credentialType);
  });

  it("Should set the verification status to true, when verified successfully", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: "did:key:abc",
      type: ["OptimaV1Credential", "VerifiableCredential"],
    };

    const tx = await optimaVCVerifier.connect(signer).verifyCredential(JSON.stringify(vc));
    await tx.wait();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(true);
  });

  it("Should revert, when type field not present in credential", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: "did:key:abc",
    };

    await expect(optimaVCVerifier.connect(signer).verifyCredential(JSON.stringify(vc)))
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Credential type not exist");
  });

  it("Should revert, when type field present but type not found", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: "did:key:abc",
      type: ["VerifiableCredential"],
    };

    await expect(optimaVCVerifier.connect(signer).verifyCredential(JSON.stringify(vc)))
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Credential type not exist");
  });
});
