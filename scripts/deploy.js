import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const networkName = chainId === 59141 ? "Linea" : chainId === 84532 ? "Base" : `Chain ${chainId}`;
  console.log(`Deploying to ${networkName} Sepolia (chainId: ${chainId})...`);
  console.log(`Deployer: ${deployer.address}`);
  const contracts = {};

  const SoulboundTokenArtifact = await hre.artifacts.readArtifact("SoulboundToken");
  const sbtFactory = new ethers.ContractFactory(SoulboundTokenArtifact.abi, SoulboundTokenArtifact.bytecode, deployer);
  const soulboundToken = await sbtFactory.deploy();
  await soulboundToken.waitForDeployment();
  contracts.SoulboundToken = await soulboundToken.getAddress();
  console.log(`  SoulboundToken: ${contracts.SoulboundToken}`);

  const CredentialRegistryArtifact = await hre.artifacts.readArtifact("CredentialRegistry");
  const crFactory = new ethers.ContractFactory(CredentialRegistryArtifact.abi, CredentialRegistryArtifact.bytecode, deployer);
  const credentialRegistry = await crFactory.deploy();
  await credentialRegistry.waitForDeployment();
  contracts.CredentialRegistry = await credentialRegistry.getAddress();
  console.log(`  CredentialRegistry: ${contracts.CredentialRegistry}`);

  const baseUrl = chainId === 59141 ? "https://sepolia.lineascan.build" : "https://sepolia.basescan.org";
  console.log(`\nVerify on ${networkName} Explorer:`);
  for (const [name, addr] of Object.entries(contracts)) {
    console.log(`  ${name}: ${baseUrl}/address/${addr}`);
  }
  console.log(JSON.stringify({ network: `${networkName.toLowerCase()}_sepolia`, chainId, deployer: deployer.address, contracts }, null, 2));
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });