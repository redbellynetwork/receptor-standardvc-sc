import { expect } from "chai";
import { ethers } from "hardhat";
import canonicalize from "canonicalize";

const credentialType = "OptimaV1Credential";
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

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.credentialType()).to.equal(credentialType);
  });

  it("Should revert, when type field not present in credential", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: idpDid,
    };
    const proofSignature = { proofPurpose: "abc" };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
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
      issuer: idpDid,
      type: ["testType"],
    };
    const proofSignature = { proofPurpose: "abc" };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Credential type not exist");
  });

  it("Should revert, when signature is not valid according to vc", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
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
      proofValue: "zaaaaa", // invalid signature
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("Signature verification failed");
  });

  it("Should revert, when wrong proof type is passed", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
    };
    const proofSignature = {
      type: "InvalidProofType", // invalid proof type
      created: "2025-03-25T07:52:36.492Z",
      proofPurpose: "assertionMethod",
      proofValue: "z2oefavncyewguGve7hnJHcinLre2MTgeRSrxsAq9xkasDzxWhy9qaK4yWDKdjpyMGpsqEm5Zkkdv9Patqhdg8rPa",
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidProof")
      .withArgs("proof type doesn't exists");
  });

  it("Should set the verification status to true, when verified successfully", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const vc = {
      "@context": ["https://www.w3.org/ns/credentials/v2"],
      id: "1c952586-1558-4eca-8935-2e52d584891a",
      type: ["OptimaV1Credential", "VerifiableCredential"],
      issuer: "did:key:zAeVG1300Ft4byWDW3NbuxooIjQvA8P16GCiL0Gj9Hg=",
      validFrom: "1742987425230",
      credentialSubject: {
        publicAddress: "0xff96eb8458e7764FFB5995adf6F7138DE66F52d3",
      },
    };

    const proofSignature = {
      type: "Ed25519Signature2020",
      created: "2025-03-26T11:10:25.237Z",
      proofPurpose: "assertionMethod",
      proofValue: "z3kjAkkNKXwoNWHi5qxF9vTvDz87P7uUrsbghHKWHFyDwgBR61oosiigxH5pjYbxdgeqK7bKMhRDCNfXACEkQCF6Z",
    };

    const tx = await optimaVCVerifier
      .connect(signer)
      .verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!);
    await tx.wait();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(true);
  });
});
