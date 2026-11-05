// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Integrity and grant metadata only. Never submit patient records, lab values, or identifiers.
contract SentinelIntegrity {
    struct Batch {
        bytes32 commitment;
        address submitter;
        uint64 submittedAt;
        string schemaVersion;
        bytes32 auditCommitment;
    }

    struct ResearchGrant {
        address researcher;
        bytes32 scopeHash;
        bytes32 purposeHash;
        uint64 expiresAt;
        bool revoked;
    }

    address public owner;
    mapping(address => bool) public authorisedSubmitters;
    mapping(bytes32 => Batch) private batches;
    mapping(bytes32 => ResearchGrant) private grants;

    event SubmitterAuthorised(address indexed submitter, bool allowed);
    event BatchCommitted(bytes32 indexed batchId, bytes32 indexed commitment, address indexed submitter, uint64 submittedAt, string schemaVersion, bytes32 auditCommitment);
    event GrantUpdated(bytes32 indexed grantId, address indexed researcher, bytes32 scopeHash, bytes32 purposeHash, uint64 expiresAt, bool revoked);

    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    modifier onlySubmitter() {
        require(authorisedSubmitters[msg.sender], "submitter not authorised");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorisedSubmitters[msg.sender] = true;
        emit SubmitterAuthorised(msg.sender, true);
    }

    function setSubmitter(address submitter, bool allowed) external onlyOwner {
        authorisedSubmitters[submitter] = allowed;
        emit SubmitterAuthorised(submitter, allowed);
    }

    function commitSourceBatch(bytes32 batchId, bytes32 commitment, string calldata schemaVersion, bytes32 auditCommitment) external onlySubmitter {
        require(batches[batchId].submittedAt == 0, "batch already committed");
        require(commitment != bytes32(0), "commitment required");
        batches[batchId] = Batch(commitment, msg.sender, uint64(block.timestamp), schemaVersion, auditCommitment);
        emit BatchCommitted(batchId, commitment, msg.sender, uint64(block.timestamp), schemaVersion, auditCommitment);
    }

    function getBatch(bytes32 batchId) external view returns (Batch memory) {
        return batches[batchId];
    }

    function grantResearch(bytes32 grantId, address researcher, bytes32 scopeHash, bytes32 purposeHash, uint64 expiresAt) external onlyOwner {
        require(researcher != address(0), "researcher required");
        grants[grantId] = ResearchGrant(researcher, scopeHash, purposeHash, expiresAt, false);
        emit GrantUpdated(grantId, researcher, scopeHash, purposeHash, expiresAt, false);
    }

    function revokeResearch(bytes32 grantId) external onlyOwner {
        ResearchGrant storage grant = grants[grantId];
        require(grant.researcher != address(0), "grant not found");
        grant.revoked = true;
        emit GrantUpdated(grantId, grant.researcher, grant.scopeHash, grant.purposeHash, grant.expiresAt, true);
    }

    function isGrantActive(bytes32 grantId, address researcher, bytes32 scopeHash, bytes32 purposeHash) external view returns (bool) {
        ResearchGrant memory grant = grants[grantId];
        return grant.researcher == researcher && grant.scopeHash == scopeHash && grant.purposeHash == purposeHash && !grant.revoked && grant.expiresAt >= block.timestamp;
    }
}
