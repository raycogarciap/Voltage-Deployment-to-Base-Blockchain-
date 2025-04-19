// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltyModule is Ownable {
    struct RoyaltyInfo {
        uint256 tokenId;
        address[] recipients;
        uint256[] percentages;
        uint256 totalPercentage;
        bool isActive;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    event RoyaltiesDistributed(uint256 indexed tokenId, uint256 totalAmount, address indexed payer);
    event RoyaltiesSet(uint256 indexed tokenId, address[] recipients, uint256[] percentages);

    function setRoyalties(uint256 _tokenId, address[] memory _recipients, uint256[] memory _percentages) public onlyOwner {
        require(_recipients.length == _percentages.length, "Length mismatch");
        uint256 total = 0;
        for (uint256 i = 0; i < _percentages.length; i++) total += _percentages[i];
        require(total == 10000, "Total percentage must be 10000");
        royalties[_tokenId] = RoyaltyInfo(_tokenId, _recipients, _percentages, total, true);
        emit RoyaltiesSet(_tokenId, _recipients, _percentages);
    }

    function distributeRoyalties(uint256 _tokenId, uint256 _totalAmount, address _payer, address _erc20Token) public onlyOwner {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        require(royalty.isActive, "Royalties not active");
        IERC20 erc20 = IERC20(_erc20Token);
        require(erc20.allowance(_payer, address(this)) >= _totalAmount, "Allowance too low");
        for (uint256 i = 0; i < royalty.recipients.length; i++) {
            uint256 paymentAmount = (_totalAmount * royalty.percentages[i]) / 10000;
            erc20.transferFrom(_payer, royalty.recipients[i], paymentAmount);
        }
        emit RoyaltiesDistributed(_tokenId, _totalAmount, _payer);
    }

    function disableRoyalties(uint256 _tokenId) public onlyOwner {
        royalties[_tokenId].isActive = false;
    }
}
