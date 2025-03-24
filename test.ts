import { ethers } from "hardhat";

const credentialType = "OptimaV1Credential";
async function main() {
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

  setTimeout(async () => {
    console.log("YourContract deployed at:", await optimaVCVerifier.getAddress());

    const obj = {
      id: "123",
      name: "abc",
      type: ["OptimaV1Credential", "VerifiableCredential"],
    };

    const stringObj = JSON.stringify(obj);

    console.log("Calling _parseJsonAndCheckType...", signerAddress);
    console.log("0", await optimaVCVerifier.verificationStatus(signerAddress));

    console.log("1", await optimaVCVerifier.credentialType());
    console.log("2", await optimaVCVerifier.abc());
    console.log("3", await optimaVCVerifier.len1());
    console.log("4", await optimaVCVerifier.len2());

    console.log({ json: stringObj });

    await optimaVCVerifier.connect(signer).verifyCredential(stringObj);

    console.log("Calling 2222...");

    setTimeout(async () => {
      console.log("0", await optimaVCVerifier.verificationStatus(signerAddress));

      console.log("1", await optimaVCVerifier.credentialType());
      console.log("2", await optimaVCVerifier.abc());
      console.log("3", await optimaVCVerifier.len1());
      console.log("4", await optimaVCVerifier.len2());
    }, 5000);
  }, 5000);
}

// Run the script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
