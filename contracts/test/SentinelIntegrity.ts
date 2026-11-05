import { expect } from "chai";
import { ethers } from "hardhat";

describe("SentinelIntegrity", function () {
  it("commits metadata only once and verifies an active grant", async function () {
    const [owner, researcher] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("SentinelIntegrity");
    const contract = await Factory.deploy();
    const batchId = ethers.id("synthetic-batch-1");
    const commitment = ethers.id("canonical-record-manifest");
    await expect(contract.commitSourceBatch(batchId, commitment, "sentinel-source-v1", ethers.id("audit")))
      .to.emit(contract, "BatchCommitted");
    await expect(contract.commitSourceBatch(batchId, commitment, "sentinel-source-v1", ethers.id("audit"))).to.be.revertedWith("batch already committed");
    const grantId = ethers.id("research-grant-1");
    const scope = ethers.id("fixed-district-rate");
    const purpose = ethers.id("synthetic-demo");
    const expiry = BigInt(Math.floor(Date.now() / 1000) + 3600);
    await contract.grantResearch(grantId, researcher.address, scope, purpose, expiry);
    expect(await contract.isGrantActive(grantId, researcher.address, scope, purpose)).to.equal(true);
    await contract.revokeResearch(grantId);
    expect(await contract.isGrantActive(grantId, researcher.address, scope, purpose)).to.equal(false);
  });
});
