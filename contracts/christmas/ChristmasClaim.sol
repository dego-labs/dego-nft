pragma solidity ^0.5.5;


import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interface/IGegoToken.sol";
import "../interface/IGegoFactoryV2.sol";   
import "../library/ReentrancyGuard.sol";

contract ChristmasClaim is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // --- Data ---
    bool private initialized; // Flag of initialize data
    address public _governance;

    bool public _isClaimStart = false;
    mapping(address => bool) public _claimMembers;
    mapping(address => bool) public _whitelist;

    uint256 public _qualityBase = 10000;

    IGegoFactoryV2 public  _gegoFactoryV2;
    IGegoToken public  _gegoTokenV2;
    address public _gegoRuleProxy;
    
    uint256 public _maxGrade = 6;
    uint256 public _maxGradeLong = 20;
    
    struct Contributor {
        IERC20  token;
        uint256 reward;
        uint256 price;// How much token can I swap for 1U?
        uint256 recvAmount;
        uint256 maxClaimKryptonite;
        uint256 curClaimKryptonite;
        uint256 ruleId;
        uint256 nftType;
        uint256 resBaseId;
        uint256 tLevel;
    }

    address[] public _contributorArr;
    mapping(address => Contributor) public _contributorMap;
    mapping(uint256=>uint256) public _gradeForU;
    uint256 public _gegoId = 10000;

    event eveGegoAdded(
        uint256 indexed id,
        uint256 grade,
        uint256 quality,
        uint256 amount,
        uint256 createdTime,
        uint256 blockNum,
        uint256 resId,
        address author,
        uint256 ruleId
    );

    event eveContributorAddReward(
        address token,
        uint256 amount
    );

    event eveGegoBurnWithdrawToken(
        address owner,
        uint256 amount,
        address erc20
    );

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    modifier checkRuleProxy {
        require(msg.sender == _gegoRuleProxy, "not this gegoRuleProxy");
        _;
    }

    // --- Init ---
    function initialize(
        IGegoFactoryV2 gegoFactoryV2, 
        uint256 gegoId, 
        IGegoToken gegoTokenV2, 
        address gegoRuleProxy) 
        public 
    {
        require(!initialized, "initialize: Already initialized!");
        _governance = msg.sender;
        _gradeForU[1] = 2;
        _gradeForU[2] = 5;
        _gradeForU[3] = 10;
        _gradeForU[4] = 15;
        _gradeForU[5] = 50;
        _gradeForU[6] = 100;
        _qualityBase = 10000;
        _maxGrade = 6;
        _maxGradeLong = 20;
        _gegoFactoryV2 = gegoFactoryV2;
        _gegoTokenV2 = gegoTokenV2;
        _gegoId = gegoId;
        _gegoRuleProxy = gegoRuleProxy;
        initReentrancyStatus();
        initialized = true;
    }


    function addWhitelist(address member) external onlyGovernance {
        _whitelist[member] = true;
    }

    function removeWhitelist(address member) external onlyGovernance {
        _whitelist[member] = false;
    }

    function setClaimStart(bool start) public onlyGovernance {
        _isClaimStart = start;
    }

     /// @dev batch set quota for user admin
    /// if openTag <=0, removed 
    function setWhitelist(address[] calldata users, bool openTag)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < users.length; i++) {
            _whitelist[users[i]] = openTag;
        }
    }

    function computerSeed() private view returns (uint256) {
        // from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        return seed;
    }

    function getGrade(uint256 quality) public view returns (uint256){
        if( quality < _qualityBase.mul(500).div(1000)){
            return 1;
        }else if( _qualityBase.mul(500).div(1000) <= quality && quality <  _qualityBase.mul(800).div(1000)){
            return 2;
        }else if( _qualityBase.mul(800).div(1000) <= quality && quality <  _qualityBase.mul(900).div(1000)){
            return 3;
        }else if( _qualityBase.mul(900).div(1000) <= quality && quality <  _qualityBase.mul(980).div(1000)){
            return 4;
        }else if( _qualityBase.mul(980).div(1000) <= quality && quality <  _qualityBase.mul(998).div(1000)){
            return 5;
        }else{
            return 6;
        }
    }

    function claim() public nonReentrant returns (uint256){
        require(_isClaimStart == true, "claim not start"); 
        require(_claimMembers[msg.sender] == false, "has claim");
        require(_whitelist[msg.sender] == true, "not in whitelist");

        _gegoId++;

        uint256 quality = 0;
        uint256 grade = 0;
        uint256 amount = 0;

        uint256 seed = computerSeed();

        uint256 contributorArrLen = _contributorArr.length;
        require(contributorArrLen >0,"claim over");
        uint256 _contributorId  = seed % _contributorArr.length;
        Contributor storage _contributor =  _contributorMap[_contributorArr[_contributorId]];

        quality = seed%_qualityBase;
        grade = getGrade(quality);
        if(grade == _maxGrade){
            if(_contributor.curClaimKryptonite >= _contributor.maxClaimKryptonite) {
                grade = grade.sub(1);
                quality = quality.sub(_maxGradeLong);
            }else{
                _contributor.curClaimKryptonite = _contributor.curClaimKryptonite.add(1);
            }
        }
        amount = _gradeForU[grade].mul(_contributor.price);
        _contributor.recvAmount = _contributor.recvAmount.add(amount);
        
        if (_contributor.recvAmount.add(_gradeForU[_maxGrade].mul(_contributor.price)) > _contributor.reward){
            removeContributorArr(_contributorId);
        }

        IGegoFactoryV2.MintData memory mintData = IGegoFactoryV2.MintData(amount, _contributor.resBaseId, _contributor.nftType, _contributor.ruleId, _contributor.tLevel);
        IGegoFactoryV2.MintExtraData memory mintExtraData = IGegoFactoryV2.MintExtraData(_gegoId, grade, quality, msg.sender);
        
        _gegoFactoryV2.gmMint(mintData, mintExtraData);

        _claimMembers[msg.sender] = true;

        emit eveGegoAdded (
            _gegoId,
            grade,
            quality,
            amount,
            block.timestamp,
            block.number,
            _contributor.resBaseId,
            msg.sender,
            _contributor.ruleId
        );
        
        return _gegoId;
    }

    function burnWithdrawToken(address erc20, address owner, uint256 amount) public checkRuleProxy nonReentrant {
        require(amount > 0, "the gego not token");
        IERC20(erc20).safeTransfer(owner, amount);
        
        emit eveGegoBurnWithdrawToken(owner, amount, erc20);
    }

    function setRuleProxy(address gegoRuleProxy)  public  onlyGovernance {
        _gegoRuleProxy  = gegoRuleProxy;
    }

    function setCurrentGegoId(uint256 id)  public  onlyGovernance {
        _gegoId = id;
    }

    function emergencySeize(IERC20 asset, uint256 amount) public onlyGovernance {
        uint256 balance = asset.balanceOf(address(this));
        require(balance > amount, "less balance");
        asset.safeTransfer(_governance, amount);
    }

    function setGovernance(address governance)  public  onlyGovernance {
        require(governance != address(0), "new governance the zero address");
        _governance = governance;
        emit GovernanceTransferred(_governance, governance);
    }


    function addContributor(address token, uint256 reward, uint256 price, uint256 ruleId, uint256 nftType, uint256 resBaseId, uint256 tLevel) 
    public 
    onlyGovernance 
    {
        if (_contributorMap[token].token == IERC20(0x0)){
            _contributorArr.push(token);
            Contributor memory _contributor;
            _contributor.token = IERC20(token);
            
            uint256 balanceBefore = _contributor.token.balanceOf(address(this));
            _contributor.token.safeTransferFrom(msg.sender, address(this), reward);
            uint256 balanceEnd = _contributor.token.balanceOf(address(this));

            _contributor.reward = balanceEnd.sub(balanceBefore);
            _contributor.price = price;
            _contributor.recvAmount = 0;
            _contributor.maxClaimKryptonite = 10;
            _contributor.curClaimKryptonite = 0;
            _contributor.ruleId = ruleId;
            _contributor.nftType = nftType;
            _contributor.resBaseId = resBaseId;
            _contributor.tLevel = tLevel;
            _contributorMap[token] = _contributor;
        }
    }

    function setContributor(address token,uint256 reward,uint256 price,uint256 ruleId,uint256 nftType) public onlyGovernance {
        if (_contributorMap[token].token != IERC20(0x0)){
            Contributor storage _contributor = _contributorMap[token];
            _contributor.token = IERC20(token);
            _contributor.reward = reward;
            _contributor.price = price;
            _contributor.ruleId = ruleId;
            _contributor.nftType = nftType;
        }
    }


    function setContributorAddReward(address token,uint256 addedReward) public onlyGovernance {
        if (_contributorMap[token].token != IERC20(0x0)){
            Contributor storage _contributor = _contributorMap[token];

            uint256 balanceBefore = _contributor.token.balanceOf(address(this));
            _contributor.token.safeTransferFrom(msg.sender, address(this), addedReward);
            uint256 balanceEnd = _contributor.token.balanceOf(address(this));
            
            uint256 realAddedReward = balanceEnd.sub(balanceBefore);
            _contributor.reward = _contributor.reward.add(realAddedReward);
            bool inArray = false;
            for (uint256 i = 0;i<_contributorArr.length; i++){
                if (_contributorArr[i] == token){
                    inArray = true;
                }
            }
            if (!inArray){
                _contributorArr.push(token);
            }
            emit eveContributorAddReward(token,realAddedReward);
        }
    }

    function removeContributorArr(uint256 _index) private returns(bool) {
        if (_index >= _contributorArr.length) {
            return false;
        }

        uint256 contributorArrIndex = _contributorArr.length-1;
        address tailAddress = _contributorArr[contributorArrIndex];
        _contributorArr[_index] = tailAddress;
        _contributorArr[contributorArrIndex] = address(0x0);
        _contributorArr.length--;

        return true;
    }

    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}
