pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";
import "../interface/IGegoFactoryV2.sol";
import "../interface/IGegoRuleProxy.sol";
import "../interface/IChristmasClaim.sol";

contract GegoChristmasClaimProxy is IGegoRuleProxy{
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- Data ---
    bool private initialized; // Flag of initialize data
    address public _governance;

    uint256 public _qualityBase = 10000;
    uint256 public _maxGrade = 6;
    uint256 public _maxGradeLong = 20;
    uint256 public _maxTLevel = 6;

    bool public _canAirdrop = false;
    uint256 public _airdopMintAmount = 5 * (10**15);
    IERC20 public _airdropToken = IERC20(0x0);
    IChristmasClaim public _christmasClaim = IChristmasClaim(0x0);
    struct RuleData{

        uint256 minMintAmount;
        uint256 maxMintAmount;
        uint256 costErc20Amount;
        address mintErc20;
        address costErc20;
        uint256 minBurnTime;
        uint256 tLevel;
        bool canMintMaxGrade;
        bool canMintMaxTLevel;

    }

    address public _costErc20Pool = address(0x0);
    IGegoFactoryV2 public _factory = IGegoFactoryV2(0x0);

    event eSetRuleData(uint256 ruleId, uint256 minMintAmount, uint256 maxMintAmount, uint256 costErc20Amount, address mintErc20, address costErc20, bool canMintMaxGrade,bool canMintMaxTLevel,uint256 minBurnTime);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(uint256 => RuleData) public _ruleData;
    mapping(uint256 => bool) public _ruleSwitch;
    
    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    

    // --- Init ---
    function initialize(
        address costErc20Pool, 
        address airdropToken, 
        address christmasClaim) 
        public 
    {
        require(!initialized, "initialize: Already initialized!");
        _governance = msg.sender;
        _costErc20Pool = costErc20Pool;
        _airdropToken = IERC20(airdropToken);
        _christmasClaim = IChristmasClaim(christmasClaim);

        _qualityBase = 10000;
        _maxGrade = 6;
        _maxGradeLong = 20;
        _maxTLevel = 6;
        _canAirdrop = false;
        _airdopMintAmount = 5 * (10**15);
        initialized = true;
    }

    function setGovernance(address governance)  public  onlyGovernance {
        require(governance != address(0), "new governance the zero address");
        _governance = governance;
        emit GovernanceTransferred(_governance, governance);
    }

    function setAirdropAmount(uint256 value) public onlyGovernance{
        _airdopMintAmount =  value;
    }

    function enableAirdrop(bool b) public onlyGovernance{
        _canAirdrop =  b;
    }


    function setQualityBase(uint256 val) public onlyGovernance{
        _qualityBase =  val;
    }

    function setMaxGrade(uint256 val) public onlyGovernance{
        _maxGrade =  val;
    }

    function setMaxTLevel(uint256 val) public onlyGovernance{
        _maxTLevel =  val;
    }

    function setMaxGradeLong(uint256 val) public onlyGovernance{
        _maxGradeLong =  val;
    }


    function setAirdropContract(address airdropToken)  public  
        onlyGovernance{
        _airdropToken = IERC20(airdropToken);
    }

    function setRuleData(
        uint256 ruleId, 
        uint256 minMintAmount, 
        uint256 maxMintAmount, 
        uint256 costErc20Amount, 
        address mintErc20, 
        address costErc20,
        uint256 minBurnTime,
        uint256 tLevel,
        bool canMintMaxGrade,
        bool canMintMaxTLevel
         )
        public
        onlyGovernance
    {
        _ruleData[ruleId].minMintAmount = minMintAmount;
        _ruleData[ruleId].maxMintAmount = maxMintAmount;
        _ruleData[ruleId].costErc20Amount = costErc20Amount;
        _ruleData[ruleId].mintErc20 = mintErc20;
        _ruleData[ruleId].costErc20 = costErc20;
        _ruleData[ruleId].minBurnTime = minBurnTime;
        _ruleData[ruleId].canMintMaxGrade = canMintMaxGrade;
        _ruleData[ruleId].canMintMaxTLevel = canMintMaxTLevel;
        _ruleData[ruleId].tLevel = tLevel;

        _ruleSwitch[ruleId] = false;

        emit eSetRuleData( ruleId,  minMintAmount,  maxMintAmount,  costErc20Amount,  mintErc20,  costErc20, canMintMaxGrade, canMintMaxTLevel,minBurnTime);
    }


     function enableRule( uint256 ruleId,bool enable )         
        public
        onlyGovernance 
     {
        _ruleSwitch[ruleId] = enable;
     }

     function setFactory( address factory )         
        public
        onlyGovernance 
     {
        _factory = IGegoFactoryV2(factory);
     }

    function cost( MintParams calldata params, Cost721Asset calldata costSet1, Cost721Asset calldata costSet2 ) external returns (  uint256 mintAmount,address mintErc20 ){
        require( _factory == IGegoFactoryV2(msg.sender)," invalid factory caller" );
       (mintAmount,mintErc20) =  _cost(params,costSet1,costSet2);
    } 

    function destroy(  address owner, IGegoToken.Gego calldata gego) external {
        require( _factory == IGegoFactoryV2(msg.sender)," invalid factory caller" );
        
        // rule proxy ignore mint time
        if( _factory.isRulerProxyContract(owner) == false){
            uint256 minBurnTime = _ruleData[gego.ruleId].minBurnTime;
            require( (block.timestamp - gego.createdTime) >=  minBurnTime, "< minBurnTime"  );
        }

        // IERC20 erc20 = IERC20(gego.erc20);
        // erc20.safeTransfer(owner, gego.amount);
        _christmasClaim.burnWithdrawToken(gego.erc20, owner, gego.amount);
    } 


    function generate(address user , uint256 ruleId ) external view returns (IGegoToken.Gego memory gego ){
        require( _factory == IGegoFactoryV2(msg.sender) ," invalid factory caller" );
        require(_ruleSwitch[ruleId], " rule is closed ");
        require(false, "can't mint");
        user;
        IGegoToken.Gego memory _gego;
        return _gego;
    } 

    function _cost( MintParams memory params, Cost721Asset memory costSet1, Cost721Asset memory costSet2 ) internal returns (  uint256 mintAmount,address mintErc20 ){
        // require( _ruleData[params.ruleId].mintErc20 != address(0x0), "invalid mintErc20 rule !");
        // require( _ruleData[params.ruleId].costErc20 != address(0x0), "invalid costErc20 rule !");
        // require( params.amount >= _ruleData[params.ruleId].minMintAmount && params.amount < _ruleData[params.ruleId].maxMintAmount, "invalid mint amount!");

        // IERC20 mintIErc20 = IERC20(_ruleData[params.ruleId].mintErc20);
        // uint256 balanceBefore = mintIErc20.balanceOf(address(this));
        // mintIErc20.safeTransfer(params.user, address(this), params.amount);
        // uint256 balanceEnd = mintIErc20.balanceOf(address(this));

        uint256 costErc20Amount = _ruleData[params.ruleId].costErc20Amount;
        if(costErc20Amount > 0){
            IERC20 costErc20 = IERC20(_ruleData[params.ruleId].costErc20);
            costErc20.safeTransferFrom(params.user, _costErc20Pool, costErc20Amount);
        }

        costSet1;
        costSet2;

        mintAmount = params.amount;
        mintErc20 = _ruleData[params.ruleId].mintErc20;

        _airdrop(params.user);
    } 

    function _airdrop(address user) internal  {
        if(_canAirdrop){
            _airdropToken.mint(user, _airdopMintAmount); 
        }
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

    function computerSeed( address user ) internal view returns (uint256) {
        // from fomo3D
        uint256 seed = uint256(keccak256(abi.encodePacked(
            //(user.balance).add
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(user)))) / (now)).add
            (block.number)
            
        )));
        return seed;
    }


}
