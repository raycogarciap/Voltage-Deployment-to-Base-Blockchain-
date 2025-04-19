const { ethers, run } = require("hardhat");
const fs = require("fs");
const path = "./scripts/deployments.json";

async function verifyContract(address, args = []) {
  try {
    await run("verify:verify", { address, constructorArguments: args });
    console.log(`✓ Verified: ${address}`);
  } catch (err) {
    console.warn(`⚠ Verification failed for ${address}: ${err.message}`);
  }
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const deployLog = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path)) : {
    _meta: {
      deployer: deployer.address,
      timestamp: new Date().toISOString()
    }
  };

  console.log(`Deploying from: ${deployer.address}`);
  console.log(`Network: ${await deployer.provider.getNetwork().then(n => n.name)}`);
  console.log("—".repeat(50));

  if (!deployLog.licenseModule) {
    const LicenseModule = await ethers.getContractFactory("LicenseModule");
    const license = await LicenseModule.deploy();
    await license.deployed();
    console.log("✓ LicenseModule deployed at:", license.address);
    deployLog.licenseModule = license.address;
    await verifyContract(license.address);
  } else {
    console.log("✓ Skipped LicenseModule (already deployed)");
  }

  if (!deployLog.royaltyModule) {
    const RoyaltyModule = await ethers.getContractFactory("RoyaltyModule");
    const royalty = await RoyaltyModule.deploy();
    await royalty.deployed();
    console.log("✓ RoyaltyModule deployed at:", royalty.address);
    deployLog.royaltyModule = royalty.address;
    await verifyContract(royalty.address);
  } else {
    console.log("✓ Skipped RoyaltyModule (already deployed)");
  }

  if (!deployLog.defiModule) {
    const dummyDeFiPlatform = ethers.constants.AddressZero;
    const DeFiModule = await ethers.getContractFactory("DeFiIntegrationModule");
    const defi = await DeFiModule.deploy(dummyDeFiPlatform);
    await defi.deployed();
    console.log("✓ DeFiIntegrationModule deployed at:", defi.address);
    deployLog.defiModule = defi.address;
    await verifyContract(defi.address, [dummyDeFiPlatform]);
  } else {
    console.log("✓ Skipped DeFiIntegrationModule (already deployed)");
  }

  if (!deployLog.voltageController) {
    const currency = "0x4200000000000000000000000000000000000006";
    const wrappedNative = currency;
    const Controller = await ethers.getContractFactory("VoltageController");

    const controller = await Controller.deploy(
      deployLog.licenseModule,
      deployLog.royaltyModule,
      deployLog.defiModule,
      currency,
      wrappedNative
    );
    await controller.deployed();
    console.log("✓ VoltageController deployed at:", controller.address);
    deployLog.voltageController = controller.address;

    await verifyContract(controller.address, [
      deployLog.licenseModule,
      deployLog.royaltyModule,
      deployLog.defiModule,
      currency,
      wrappedNative
    ]);
  } else {
    console.log("✓ Skipped VoltageController (already deployed)");
  }

  fs.writeFileSync(path, JSON.stringify(deployLog, null, 2));
  console.log(`\n✓ All done. Deployment details saved to ${path}`);
}

main().catch((error) => {
  console.error("✖ Deployment failed:", error);
  process.exit(1);
});
