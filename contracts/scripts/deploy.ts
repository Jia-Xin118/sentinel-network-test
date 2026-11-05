import { ethers, network } from "hardhat";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

async function main() {
  const [deployer] = await ethers.getSigners();
  const Factory = await ethers.getContractFactory("SentinelIntegrity");
  const contract = await Factory.deploy();
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  const metadata = { contractAddress: address, chainId: Number((await ethers.provider.getNetwork()).chainId), deployedBy: deployer.address, network: network.name, deployedAt: new Date().toISOString() };
  const target = resolve(__dirname, "../../backend/app/chain/contract_metadata.json");
  mkdirSync(resolve(__dirname, "../../backend/app/chain"), { recursive: true });
  writeFileSync(target, JSON.stringify(metadata, null, 2));
  console.log(JSON.stringify(metadata, null, 2));
  console.log(`CHAIN_CONTRACT_ADDRESS=${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
