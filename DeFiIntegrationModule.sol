// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeFiIntegrationModule is Ownable {
    struct StakedAsset {
        uint256 tokenId;
        address owner;
        uint256 stakedAmount;
        uint256 stakingStart;
        bool isStaked;
    }

    mapping(uint256 => StakedAsset) public stakedAssets;
    address public externalDeFiPlatform;

    event AssetStaked(uint256 indexed tokenId, address indexed owner, uint256 stakedAmount, uint256 stakingStart);
    event AssetUnstaked(uint256 indexed tokenId, address indexed owner, uint256 unstakedAmount);

    constructor(address _externalDeFiPlatform) {
        externalDeFiPlatform = _externalDeFiPlatform;
    }

    function stakeTokens(uint256 _tokenId, uint256 _amount, address _erc20Token) public {
        require(_amount > 0, "Stake > 0");
        require(!stakedAssets[_tokenId].isStaked, "Already staked");
        IERC20 token = IERC20(_erc20Token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        stakedAssets[_tokenId] = StakedAsset(_tokenId, msg.sender, _amount, block.timestamp, true);
        emit AssetStaked(_tokenId, msg.sender, _amount, block.timestamp);
    }

    function unstakeTokens(uint256 _tokenId, address _erc20Token) public {
        StakedAsset storage asset = stakedAssets[_tokenId];
        require(asset.isStaked, "Not staked");
        require(asset.owner == msg.sender, "Not owner");
        uint256 amount = asset.stakedAmount;
        IERC20 token = IERC20(_erc20Token);
        token.transfer(asset.owner, amount);
        asset.isStaked = false;
        emit AssetUnstaked(_tokenId, msg.sender, amount);
    }

    function getStakingInfo(uint256 _tokenId) public view returns (StakedAsset memory) {
        return stakedAssets[_tokenId];
    }

    function setExternalDeFiPlatform(address _newPlatform) public onlyOwner {
        externalDeFiPlatform = _newPlatform;
    }
}
