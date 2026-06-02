// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoulboundToken is ReentrancyGuard, Ownable {
    constructor() Ownable(msg.sender) {}

    struct CredentialData {
        address issuer;
        address subject;
        string credentialType;
        bytes32 dataHash;
        uint256 issuedAt;
        uint256 expiresAt;
        bool exists;
    }

    uint256 private _tokenIds;
    mapping(uint256 => CredentialData) private _credentials;
    mapping(address => uint256[]) private _subjectTokens;
    mapping(address => uint256[]) private _issuerTokens;

    event CredentialMinted(
        uint256 indexed tokenId,
        address indexed issuer,
        address indexed subject,
        string credentialType
    );
    event CredentialBurned(uint256 indexed tokenId, address indexed owner);
    event CredentialRevoked(uint256 indexed tokenId, address indexed issuer);

    error TokenDoesNotExist(uint256 tokenId);
    error TokenExpired(uint256 tokenId);
    error NotIssuer(address caller, address issuer);
    error NotOwnerOrIssuer(address caller);
    error CredentialAlreadyExists(uint256 tokenId);
    error InvalidAddress();
    error EmptyCredentialType();

    modifier onlyIssuer(uint256 tokenId) {
        if (_credentials[tokenId].issuer != msg.sender) {
            revert NotIssuer(msg.sender, _credentials[tokenId].issuer);
        }
        _;
    }

    modifier onlyOwnerOrIssuer(uint256 tokenId) {
        if (
            msg.sender != owner() &&
            msg.sender != _credentials[tokenId].issuer
        ) {
            revert NotOwnerOrIssuer(msg.sender);
        }
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        if (!_credentials[tokenId].exists) {
            revert TokenDoesNotExist(tokenId);
        }
        _;
    }

    function mint(
        address subject,
        string calldata credentialType,
        bytes32 dataHash,
        uint256 expiresAt
    ) external onlyIssuer(0) returns (uint256) {
        if (subject == address(0)) revert InvalidAddress();
        if (bytes(credentialType).length == 0) revert EmptyCredentialType();

        uint256 tokenId = _tokenIds++;
        uint256 issuedAt = block.timestamp;

        _credentials[tokenId] = CredentialData({
            issuer: msg.sender,
            subject: subject,
            credentialType: credentialType,
            dataHash: dataHash,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            exists: true
        });

        _subjectTokens[subject].push(tokenId);
        _issuerTokens[msg.sender].push(tokenId);

        emit CredentialMinted(
            tokenId,
            msg.sender,
            subject,
            credentialType
        );

        return tokenId;
    }

    function burn(uint256 tokenId)
        external
        tokenExists(tokenId)
        onlyOwnerOrIssuer(tokenId)
    {
        CredentialData storage credential = _credentials[tokenId];
        address subject = credential.subject;

        delete _credentials[tokenId];

        uint256[] storage subjectTokenIds = _subjectTokens[subject];
        for (uint256 i = 0; i < subjectTokenIds.length; i++) {
            if (subjectTokenIds[i] == tokenId) {
                subjectTokenIds[i] = subjectTokenIds[subjectTokenIds.length - 1];
                subjectTokenIds.pop();
                break;
            }
        }

        uint256[] storage issuerTokenIds = _issuerTokens[credential.issuer];
        for (uint256 i = 0; i < issuerTokenIds.length; i++) {
            if (issuerTokenIds[i] == tokenId) {
                issuerTokenIds[i] =
                    issuerTokenIds[issuerTokenIds.length - 1];
                issuerTokenIds.pop();
                break;
            }
        }

        emit CredentialBurned(tokenId, subject);
    }

    function verify(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bool)
    {
        CredentialData storage credential = _credentials[tokenId];
        if (credential.expiresAt > 0 && credential.expiresAt < block.timestamp) {
            revert TokenExpired(tokenId);
        }
        return true;
    }

    function getTokenData(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (
            address issuer,
            address subject,
            string memory credentialType,
            bytes32 dataHash,
            uint256 issuedAt,
            uint256 expiresAt
        )
    {
        CredentialData storage credential = _credentials[tokenId];
        return (
            credential.issuer,
            credential.subject,
            credential.credentialType,
            credential.dataHash,
            credential.issuedAt,
            credential.expiresAt
        );
    }

    function getSubjectTokens(address subject)
        external
        view
        returns (uint256[] memory)
    {
        return _subjectTokens[subject];
    }

    function getIssuerTokens(address issuer)
        external
        view
        returns (uint256[] memory)
    {
        return _issuerTokens[issuer];
    }
}
