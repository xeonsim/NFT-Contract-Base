// SPDX-License-Identifier: MIT
// File: contracts\KIP17Kbirdz.sol

import "./KIP17Metadata.sol";
import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";
import "./utils/String.sol";

pragma solidity ^0.5.0;
contract NFT is KIP17Metadata, Ownable {
    using SafeMath for uint256;

    // bot preventing functions
    //=========================================================================
    mapping (address => uint256) private lastCallBlockNumber;
    
    uint256 private antibotInterval;
    
    function updateAntibotInterval(uint256 _interval) external onlyOwner {
        antibotInterval = _interval;
    }
    //=========================================================================

    // NFT invocations
    //=========================================================================
    uint256 public invocations;
    uint256 private maxInvocations = 100; //this variable decides total supply of your NFT
    //=========================================================================

    // locking NFT project 
    //=========================================================================
    bool private locked = false;
    
    function setLocked() public onlyOwner {
        locked = true;
        active = false;
        WhitelistMintEnabled = false;
    }
    //=========================================================================

    // modifiers
    //=========================================================================
    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }
    
    modifier onlyUnlocked(){
        require(!locked,"this NFT project is unlocked");
        _;
    }
    //=========================================================================

    // activating NFT project
    //=========================================================================
    bool private active;
    
    function toggleActive() public onlyOwner onlyUnlocked {
        active = !active;
    }
    
    function getActiveStatus() public view onlyUnlocked returns (bool){
        return active;
    }
    //=========================================================================

    // setting token price 
    //=========================================================================
    uint256 private PricePerTokenInPeb;
    
    function updatePricePerTokenInPeb(uint256 _pricePerTokenInPeb) onlyOwner onlyUnlocked public {
        PricePerTokenInPeb = _pricePerTokenInPeb;
    }
    //=========================================================================


    // limiting minting numbers
    //=========================================================================
    uint256 private mintLimitPerBlock;
    
    function updateMintLimitPerBlock(uint256 _limit) onlyOwner onlyUnlocked public {
        mintLimitPerBlock = _limit;
    }
    //=========================================================================


    // setting mint start block number
    //=========================================================================
    uint256 private mintStartBlockNumber;
    
    function updateMintStartBlockNumber( uint256 _blockNumber) onlyOwner onlyUnlocked public {
        mintStartBlockNumber = _blockNumber;
    }
    //=========================================================================

    // base IPFS URI functions
    //=========================================================================
    string private BaseIpfsURI;
    
    function updateBaseIpfsURI( string memory _BaseIpfsURI) onlyOwner onlyUnlocked public {
        BaseIpfsURI = _BaseIpfsURI;
    }

    function BaseIpfsURIInfo() public view onlyUnlocked returns (string memory) {
        return BaseIpfsURI;
    }
    //=========================================================================

    // getting information of tokens that owner has
    //=========================================================================
    function tokensOfOwner(address owner) external view onlyUnlocked returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }
    //=========================================================================

    // royalty functions
    //=========================================================================
    mapping(uint256 => uint256) private tokenIdToRoyaltyPercentage;

    uint256 public royaltyPercentage = 10;

    function updateRoyaltyPercentage(uint256 _percentage) external onlyUnlocked onlyOwner{
        royaltyPercentage = _percentage;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view onlyUnlocked returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * tokenIdToRoyaltyPercentage[_tokenId] / 100);
        return (owner(), royaltyAmount);
    }

    function _setTokenRoyalty(uint256 _tokenId) internal {
        tokenIdToRoyaltyPercentage[_tokenId] = royaltyPercentage; 
    }
    //=========================================================================


    //withdraw
    //=========================================================================
    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call.value(address(this).balance)("");
        require(success);
    }
    //=========================================================================

    
    //getting minting information
    //=========================================================================
    function mintingInformation() public view onlyUnlocked returns (uint256[6] memory){
        return[antibotInterval, mintLimitPerBlock, mintStartBlockNumber, royaltyPercentage, invocations, maxInvocations];
    }
    //=========================================================================


    // public mint 
    //=========================================================================
    function publicMint(uint256 requestedCount) external payable onlyUnlocked {
        require(active, "The public sale is not enabled!");
        require(lastCallBlockNumber[msg.sender].add(antibotInterval) < block.number, "Bot is not allowed");
        require(block.number >= mintStartBlockNumber, "Not yet started");
        require(requestedCount > 0 && requestedCount <= mintLimitPerBlock, "Too many requests or zero request");
        require(msg.value == PricePerTokenInPeb.mul(requestedCount), "Not enough Klay");
        require(invocations.add(requestedCount) <= maxInvocations + 1, "Exceed max amount");


        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(msg.sender, invocations);
            _setTokenRoyalty(invocations);
            invocations.add(1);
        }
        lastCallBlockNumber[msg.sender] = block.number;
    }
    //=========================================================================

    //Whitelist Mint
    //=========================================================================
    mapping(address => bool) public whitelistAddress;
    mapping(address => bool) public whitelistClaimed;

    bool private WhitelistMintEnabled;  
    
    function addWhitelist(address _whitelistAddress) external onlyOwner onlyUnlocked {
        whitelistAddress[_whitelistAddress]=true;
    }

    function removeWhitelist(address _whitelistAddress) external onlyOwner onlyUnlocked{
        whitelistAddress[_whitelistAddress]=false;
    }

    function toggleWhitelistMintEnabled() external onlyOwner onlyUnlocked{
        WhitelistMintEnabled = !WhitelistMintEnabled;
    }

    function whitelistMint(uint256 requestedCount) external payable onlyUnlocked{
        require(WhitelistMintEnabled, "The whitelist sale is not enabled!");
        require(msg.value == PricePerTokenInPeb.mul(requestedCount), "Not enough Klay");
        require(!whitelistClaimed[msg.sender],"whitelist already claimed");
        require(whitelistAddress[msg.sender],"sender is not on Whitelist");
        require(requestedCount > 0 && requestedCount <= mintLimitPerBlock, "Too many requests or zero request");
        
        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(msg.sender, invocations);
            _setTokenRoyalty(invocations);
            invocations.add(1);
        }
        whitelistClaimed[msg.sender]=true;
    }
    //=========================================================================

    //Airdrop Mint
    //=========================================================================
    function airDropMint(address user, uint256 requestedCount) external onlyOwner onlyUnlocked{
        require(requestedCount > 0, "zero request");
        for(uint256 i = 0; i < requestedCount; i++) {
            _mint(user, invocations);
            _setTokenRoyalty(invocations);
            invocations.add(1);
        }
    }
    //=========================================================================

    //token URI
    //=========================================================================
    function tokenURI(uint256 _tokenId) external view onlyValidTokenId(_tokenId) onlyUnlocked returns (string memory) {
        return bytes(BaseIpfsURI).length > 0
            ? string(abi.encodePacked(BaseIpfsURI, String.uint2str(_tokenId),".json"))
            : "";
    }
    //=========================================================================

}