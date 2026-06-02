// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CredentialRegistry is ReentrancyGuard, Ownable {
    struct Issuer {
        address issuerAddress;
        string name;
        uint256 reputation;
        bool registered;
        uint256 credentialsIssued;
        uint256 credentialsRevoked;
    }

    struct CredentialRecord {
        uint256 tokenId;
        address issuer;
        address subject;
        string credentialType;
        bytes32 dataHash;
        uint256 issuedAt;
        uint256 expiresAt;
        bool revoked;
        bool verified;
    }

    mapping(address => Issuer) private _issuers;
    mapping(uint256 => CredentialRecord) private _credentials;
    mapping(address => uint256[]) private _issuerCredentialIds;
    mapping(string => bool) private _supportedCredentialTypes;
    uint256 private _credentialCounter;

    event IssuerRegistered(
        address indexed issuer,
        string name,
        uint256 reputation
    );
    event IssuerReputationUpdated(
        address indexed issuer,
        uint256 oldReputation,
        uint256 newReputation
    );
    event CredentialIssued(
        uint256 indexed credentialId,
        address indexed issuer,
        address indexed subject,
        string credentialType
    );
    event CredentialVerified(
        uint256 indexed credentialId,
        address indexed verifier
    );
    event CredentialRevoked(
        uint256 indexed credentialId,
        address indexed issuer
    );
    event CredentialTypeAdded(string credentialType);
    event CredentialTypeRemoved(string credentialType);

    error IssuerAlreadyRegistered(address issuer);
    error IssuerNotRegistered(address issuer);
    error InvalidAddress();
    error EmptyName();
    error CredentialTypeNotSupported(string credentialType);
    error CredentialAlreadyRevoked(uint256 credentialId);
    error CredentialNotRevoked(uint256 credentialId);
    error InsufficientReputation(address issuer);
    error OnlyIssuerOrOwner(address caller);
    error CredentialDoesNotExist(uint256 credentialId);
    error ReputationCannotBeNegative();
    error ReputationOverflow();

    modifier onlyIssuerOrOwner(address issuer) {
        if (msg.sender != owner() && msg.sender != issuer) {
            revert OnlyIssuerOrOwner(msg.sender);
        }
        _;
    }

    modifier issuerRegistered(address issuer) {
        if (!_issuers[issuer].registered) {
            revert IssuerNotRegistered(issuer);
        }
        _;
    }

    modifier credentialExists(uint256 credentialId) {
        if (_credentials[credentialId].issuedAt == 0) {
            revert CredentialDoesNotExist(credentialId);
        }
        _;
    }

    constructor() Ownable(msg.sender) {
        _supportedCredentialTypes["identity"] = true;
        _supportedCredentialTypes["education"] = true;
        _supportedCredentialTypes["professional"] = true;
        _supportedCredentialTypes["membership"] = true;
    }

    function registerIssuer(address issuerAddress, string calldata name, uint256 initialReputation)
        external
        onlyOwner
    {
        if (issuerAddress == address(0)) revert InvalidAddress();
        if (bytes(name).length == 0) revert EmptyName();
        if (_issuers[issuerAddress].registered) {
            revert IssuerAlreadyRegistered(issuerAddress);
        }

        _issuers[issuerAddress] = Issuer({
            issuerAddress: issuerAddress,
            name: name,
            reputation: initialReputation,
            registered: true,
            credentialsIssued: 0,
            credentialsRevoked: 0
        });

        emit IssuerRegistered(issuerAddress, name, initialReputation);
    }

    function updateIssuerReputation(address issuer, uint256 newReputation)
        external
        onlyOwner
        issuerRegistered(issuer)
    {
        uint256 oldReputation = _issuers[issuer].reputation;
        _issuers[issuer].reputation = newReputation;

        emit IssuerReputationUpdated(issuer, oldReputation, newReputation);
    }

    function addCredentialType(string calldata credentialType) external onlyOwner {
        if (!_supportedCredentialTypes[credentialType]) {
            _supportedCredentialTypes[credentialType] = true;
            emit CredentialTypeAdded(credentialType);
        }
    }

    function removeCredentialType(string calldata credentialType) external onlyOwner {
        if (_supportedCredentialTypes[credentialType]) {
            _supportedCredentialTypes[credentialType] = false;
            emit CredentialTypeRemoved(credentialType);
        }
    }

    function issueCredential(
        address subject,
        string calldata credentialType,
        bytes32 dataHash,
        uint256 expiresAt
    )
        external
        nonReentrant
        issuerRegistered(msg.sender)
        returns (uint256)
    {
        if (subject == address(0)) revert InvalidAddress();
        if (!_supportedCredentialTypes[credentialType]) {
            revert CredentialTypeNotSupported(credentialType);
        }

        Issuer storage issuer = _issuers[msg.sender];
        if (issuer.reputation < 100) {
            revert InsufficientReputation(msg.sender);
        }

        uint256 credentialId = _credentialCounter++;

        _credentials[credentialId] = CredentialRecord({
            tokenId: credentialId,
            issuer: msg.sender,
            subject: subject,
            credentialType: credentialType,
            dataHash: dataHash,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            revoked: false,
            verified: false
        });

        _issuerCredentialIds[msg.sender].push(credentialId);
        issuer.credentialsIssued++;

        emit CredentialIssued(
            credentialId,
            msg.sender,
            subject,
            credentialType
        );

        return credentialId;
    }

    function verifyCredential(uint256 credentialId)
        external
        credentialExists(credentialId)
    {
        CredentialRecord storage credential = _credentials[credentialId];

        if (credential.revoked) {
            revert CredentialAlreadyRevoked(credentialId);
        }

        credential.verified = true;

        Issuer storage issuer = _issuers[credential.issuer];
        if (issuer.reputation < type(uint256).max - 10) {
            uint256 oldReputation = issuer.reputation;
            issuer.reputation += 10;
            emit IssuerReputationUpdated(
                credential.issuer,
                oldReputation,
                issuer.reputation
            );
        }

        emit CredentialVerified(credentialId, msg.sender);
    }

    function revokeCredential(uint256 credentialId)
        external
        credentialExists(credentialId)
        onlyIssuerOrOwner(_credentials[credentialId].issuer)
    {
        CredentialRecord storage credential = _credentials[credentialId];

        if (credential.revoked) {
            revert CredentialAlreadyRevoked(credentialId);
        }

        credential.revoked = true;

        Issuer storage issuer = _issuers[credential.issuer];
        issuer.credentialsRevoked++;

        if (issuer.reputation >= 25) {
            uint256 oldReputation = issuer.reputation;
            issuer.reputation -= 25;
            emit IssuerReputationUpdated(
                credential.issuer,
                oldReputation,
                issuer.reputation
            );
        }

        emit CredentialRevoked(credentialId, msg.sender);
    }

    function getIssuerCredentials(address issuer)
        external
        view
        issuerRegistered(issuer)
        returns (uint256[] memory)
    {
        return _issuerCredentialIds[issuer];
    }

    function getIssuer(address issuer) external view returns (Issuer memory) {
        return _issuers[issuer];
    }

    function getCredential(uint256 credentialId)
        external
        view
        credentialExists(credentialId)
        returns (CredentialRecord memory)
    {
        return _credentials[credentialId];
    }

    function isCredentialTypeSupported(string calldata credentialType)
        external
        view
        returns (bool)
    {
        return _supportedCredentialTypes[credentialType];
    }
}
