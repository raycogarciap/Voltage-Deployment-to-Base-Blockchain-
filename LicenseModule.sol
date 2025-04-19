// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LicenseModule is Ownable {
    struct License {
        uint256 tokenId;
        uint256 issuedAt;
        uint256 duration;
        uint256 maxUsage;
        uint256 usageCount;
        string region;
        bool isActive;
        address licensee;
    }

    mapping(uint256 => License) public licenses;

    event LicenseIssued(uint256 indexed tokenId, address indexed licensee, uint256 issuedAt, uint256 duration, uint256 maxUsage, string region);
    event LicenseRevoked(uint256 indexed tokenId);

    function issueLicense(uint256 _tokenId, address _licensee, uint256 _duration, uint256 _maxUsage, string memory _region) public onlyOwner {
        require(!licenses[_tokenId].isActive, "License already active");
        licenses[_tokenId] = License(_tokenId, block.timestamp, _duration, _maxUsage, 0, _region, true, _licensee);
        emit LicenseIssued(_tokenId, _licensee, block.timestamp, _duration, _maxUsage, _region);
    }

    function isLicenseValid(uint256 _tokenId) public view returns (bool) {
        License memory license = licenses[_tokenId];
        if (!license.isActive) return false;
        if (license.duration > 0 && (block.timestamp > license.issuedAt + license.duration)) return false;
        if (license.maxUsage > 0 && license.usageCount >= license.maxUsage) return false;
        return true;
    }

    function useLicense(uint256 _tokenId) public {
        require(isLicenseValid(_tokenId), "License is not valid");
        License storage license = licenses[_tokenId];
        require(license.licensee == msg.sender, "Not licensee");
        if (license.maxUsage > 0) {
            require(license.usageCount < license.maxUsage, "Usage limit reached");
            license.usageCount += 1;
        }
    }

    function revokeLicense(uint256 _tokenId) public onlyOwner {
        licenses[_tokenId].isActive = false;
        emit LicenseRevoked(_tokenId);
    }
}
