import { expect } from "chai";
import { ethers } from "hardhat";

const credentialType = "OptimaV1Credential";
const bootstrapRegistryContractAddress = ethers.getAddress(process.env.BOOTSTRAP_REGISTRY_CONTRACT_ADDRESS!);
const idpDid = process.env.IDP_DID!;

// test setup fixture
async function deployOptimaVCVerifierFixture() {
  const signer = await ethers.provider.getSigner();
  const signerAddress = await signer.getAddress();

  const JsonFormatter = await ethers.getContractFactory("JsonFormatter", signer);
  const jsonFormatter = await JsonFormatter.deploy();
  const jsonFormatterAddress = await jsonFormatter.getAddress();

  const Base58 = await ethers.getContractFactory("Base58", signer);
  const base58 = await Base58.deploy();
  const base58Address = await base58.getAddress();

  const OptimaVCVerifier = await ethers.getContractFactory("OptimaVCVerifier", {
    libraries: { JsonFormatter: jsonFormatterAddress, Base58: base58Address },
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

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType, bootstrapRegistryContractAddress);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.credentialType()).to.equal(credentialType);
  });

  it("Should revert, when type field not present in credential", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType, bootstrapRegistryContractAddress);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: idpDid,
    };
    const proofSignature = { proofPurpose: "abc" };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, JSON.stringify(vc), JSON.stringify(proofSignature))
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Credential type not exist");
  });

  it("Should revert, when type field present but type not found", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType, bootstrapRegistryContractAddress);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["VerifiableCredential"],
    };
    const proofSignature = { proofPurpose: "abc" };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, JSON.stringify(vc), JSON.stringify(proofSignature))
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Credential type not exist");
  });

  it("Should revert, when signature is not valid according to vc", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType, bootstrapRegistryContractAddress);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
    };
    const proofSignature = {
      type: "Ed25519Signature2020",
      created: "2025-03-25T07:52:36.492Z",
      proofPurpose: "assertionMethod",
      proofValue: "z2oefavncyewguGve7hnJHcinLre2MTgeRSrxsAq9xkasDzxWhy9qaK4yWDKdjpyMGpsqEm5Zkkdv9Patqhdg8rPa",
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, JSON.stringify(vc), JSON.stringify(proofSignature))
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Signature verification failed");
  });
});
