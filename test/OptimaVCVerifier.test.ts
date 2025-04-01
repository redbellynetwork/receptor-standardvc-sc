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

  const TimeParserUtils = await ethers.getContractFactory("TimeParserUtils", signer);
  const timeParserUtils = await TimeParserUtils.deploy();
  const timeParserUtilsAddress = await timeParserUtils.getAddress();

  const StringToAddressLib = await ethers.getContractFactory("StringToAddress", signer);
  const stringToAddressLib = await StringToAddressLib.deploy();
  const stringToAddressLibAddress = await stringToAddressLib.getAddress();

  const OptimaVCVerifier = await ethers.getContractFactory("OptimaVCVerifier", {
    libraries: {
      JsonFormatter: jsonFormatterAddress,
      Base58: base58Address,
      TimeParserUtils: timeParserUtilsAddress,
      StringToAddress: stringToAddressLibAddress,
    },
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

  it("Should revert, when validFrom is ahead of block timestamp", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const currentDate = new Date();
    currentDate.setDate(currentDate.getDate() + 2);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
      validFrom: currentDate.toISOString(), // validFrom ahead of current time
    };
    const proofSignature = {
      type: "Ed25519Signature2020",
      created: currentDate.toISOString(),
      proofPurpose: "assertionMethod",
      proofValue: "z2oefavncyewguGve7hnJHcinLre2MTgeRSrxsAq9xkasDzxWhy9qaK4yWDKdjpyMGpsqEm5Zkkdv9Patqhdg8rPa",
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("validFrom date must be in the past");
  });

  it("Should revert, when validUntil is behind of block timestamp", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const currentDate = new Date();
    currentDate.setDate(currentDate.getDate() - 2);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
      validFrom: "2025-03-28T16:52:00.753Z", // validFrom in past
      validUntil: currentDate.toISOString(), // validUntil behind of current time
    };
    const proofSignature = {
      type: "Ed25519Signature2020",
      created: currentDate.toISOString(),
      proofPurpose: "assertionMethod",
      proofValue: "z2oefavncyewguGve7hnJHcinLre2MTgeRSrxsAq9xkasDzxWhy9qaK4yWDKdjpyMGpsqEm5Zkkdv9Patqhdg8rPa",
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("The validUntil date cannot be in the past");
  });

  it("Should revert, when public address is not same as msg.sender", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const currentDate = new Date();
    currentDate.setDate(currentDate.getDate() + 2);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
      validFrom: "2025-03-28T16:52:00.753Z", // validFrom in past
      validUntil: currentDate.toISOString(), // validUntil ahead of current time
      credentialSubject: {
        publicAddress: "0x4bEDC01904D69db3683dEF0FCF6de852098c6b84",
      },
    };

    const proofSignature = {
      type: "Ed25519Signature2020",
      created: "2025-03-25T07:52:36.492Z",
      proofPurpose: "assertionMethod",
      proofValue: "z8oagLAKH4LwjVM56i5wBvM2EDuo1WC5pHmRGWe6Ha6BNEWeKGRiHBjHDD98jRBNe3TrSZGb6knsMTK1YwhseWPH",
    };

    await expect(
      optimaVCVerifier.connect(signer).verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!)
    )
      .to.be.revertedWithCustomError(optimaVCVerifier, "InvalidData")
      .withArgs("CredentialSubject publicAddress and msg.sender doesn't match");
  });

  it("Should revert, when signature is not valid according to vc", async function () {
    const { OptimaVCVerifier, signer, signerAddress } = await deployOptimaVCVerifierFixture();

    const optimaVCVerifier = await OptimaVCVerifier.deploy(credentialType);
    await optimaVCVerifier.waitForDeployment();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(false);

    const currentDate = new Date();
    currentDate.setDate(currentDate.getDate() + 2);

    const vc = {
      id: "123",
      issuer: idpDid,
      type: ["OptimaV1Credential", "VerifiableCredential"],
      validFrom: "2025-03-28T16:52:00.753Z", // validFrom in past
      validUntil: currentDate.toISOString(), // validUntil ahead of current time
      credentialSubject: {
        publicAddress: "0xff96eb8458e7764FFB5995adf6F7138DE66F52d3",
      },
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
      "@context": ["https://www.w3.org/ns/credentials/v2"],
      id: "9cf1de20-7c7b-49e3-bac7-106a1c895dd0",
      type: ["OptimaV1Credential", "VerifiableCredential"],
      issuer: "did:key:zAeVG1300Ft4byWDW3NbuxooIjQvA8P16GCiL0Gj9Hg=",
      validFrom: "2025-04-01T06:09:32.624Z", // validFrom in past
      validUntil: "2028-04-01T06:09:32.624Z", // valid until ahead of current time
      credentialSubject: {
        publicAddress: "0xff96eb8458e7764FFB5995adf6F7138DE66F52d3",
      },
    };
    const proofSignature = {
      type: "InvalidProofType", // invalid proof type
      created: "2025-04-01T06:09:32.625Z",
      proofPurpose: "assertionMethod",
      proofValue: "z8oagLAKH4LwjVM56i5wBvM2EDuo1WC5pHmRGWe6Ha6BNEWeKGRiHBjHDD98jRBNe3TrSZGb6knsMTK1YwhseWPH",
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
      id: "9cf1de20-7c7b-49e3-bac7-106a1c895dd0",
      type: ["OptimaV1Credential", "VerifiableCredential"],
      issuer: "did:key:zAeVG1300Ft4byWDW3NbuxooIjQvA8P16GCiL0Gj9Hg=",
      validFrom: "2025-04-01T06:09:32.624Z", // validFrom in past
      validUntil: "2028-04-01T06:09:32.624Z", // valid until ahead of current time
      credentialSubject: {
        publicAddress: "0xff96eb8458e7764FFB5995adf6F7138DE66F52d3",
      },
    };

    const proofSignature = {
      type: "Ed25519Signature2020",
      created: "2025-04-01T06:09:32.625Z",
      proofPurpose: "assertionMethod",
      proofValue: "z8oagLAKH4LwjVM56i5wBvM2EDuo1WC5pHmRGWe6Ha6BNEWeKGRiHBjHDD98jRBNe3TrSZGb6knsMTK1YwhseWPH",
    };

    const tx = await optimaVCVerifier
      .connect(signer)
      .verifyCredential(idpDid, canonicalize(vc)!, canonicalize(proofSignature)!);
    await tx.wait();

    expect(await optimaVCVerifier.verificationStatus(signerAddress)).to.equal(true);
  });
});
