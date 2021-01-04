pragma solidity ^0.5.5;


import "../interface/IERC20.sol";
import "../library/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../interface/IGegoArtToken.sol";
import "../library/ReentrancyGuard.sol";

contract GegoArtFactory is ReentrancyGuard, IERC721Receiver{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    struct GegoArt {
        uint256 id;
        uint256 createdTime;
        uint256 blockNum;
        uint256 tokenAmount;
        address tokenAddress;
        address author;
        string resName;
    }

    event GegoArtAdded(
        uint256 indexed id,
        uint256 createdTime,
        uint256 blockNum,
        uint256 tokenAmount,
        address tokenAddress,
        address author,
        string resName
    );

    event GegoArtBurn(
        uint256 indexed id,
        address tokenAddress,
        uint256 tokenAmount
    );

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);


        // --- Data ---
    bool private initialized; // Flag of initialize data

    // for minters
    mapping(address => bool) public _minters;

    mapping(uint256 => GegoArt) public _gegoArts;

    uint256 public _gegoArtId = 0;

    uint256 public _burnTime = 30 days;
    IGegoArtToken public _gegoArt = IGegoArtToken(0x0);

    IERC20 public _rewardToken = IERC20(0x0);
    uint256 public _rewardAmount = 100 finney;

    IERC20 public _costToken = IERC20(0x0);
    uint256 public _costAmount = 1 ether;
    address public _costAddress = address(0x0);


    bool public _isUserStart = false;
    bool public _hasReward = false;

    address public _governance;

    mapping(string => address) _resMap; 

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _governance = tx.origin;
    }


    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }


    // --- Init ---
    function initialize(
        address gegoArtToken,
        address rewardToken,
        uint256 rewardAmount,
        address costToken,
        uint256 costAmount,
        address costAddress,
        uint256 burnTime,
        bool isUserStart,
        bool hasReward
    ) public {
        require(!initialized, "initialize: Already initialized!");
        require(costAddress != address(0x0) , "costAddress can't be null");

        _governance = msg.sender;
    
        _gegoArt = IGegoArtToken(gegoArtToken);
        
        _rewardToken = IERC20(rewardToken);
        _rewardAmount = rewardAmount;

        _costToken = IERC20(costToken);
        _costAmount = costAmount;
        _costAddress = costAddress;

        _burnTime = burnTime;
        _isUserStart = isUserStart;
        _hasReward = hasReward;

        initReentrancyStatus();
        initialized = true;
    }

    function setGegoArtId(uint256 id) public onlyGovernance {
        _gegoArtId = id;
    }


    function setRewardAmount(uint256 value) public onlyGovernance{
        _rewardAmount =  value;
    }

    function setUserStart(bool start) public onlyGovernance {
        _isUserStart = start;
    }

    function setHasReward(bool has) public onlyGovernance {
        _hasReward = has;
    }

    function setBurnTime(uint256 burnTime) public onlyGovernance {
        _burnTime = burnTime;
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }

    function setResMap(string memory resName, address addr) public onlyGovernance {
        _resMap[resName] = addr;
    }

    /**
     * @dev set gego contract address
     */
    function setGegoArtContract(address addr)  public  
        onlyGovernance{
        _gegoArt = IGegoArtToken(addr);
    }

    /**
     * @dev set dandy contract address
     */
    function setRewardContract(address addr)  public  
        onlyGovernance{
        _rewardToken = IERC20(addr);
    }


    function getGegoArt(uint256 tokenId)
        external view
        returns (
            uint256 createdTime,
            uint256 blockNum,
            uint256 tokenAmount,
            address tokenAddress,
            address author,
            string memory resName
        )
    {
        GegoArt storage gegoArt = _gegoArts[tokenId];
        require(gegoArt.id > 0, "not exist");
        createdTime = gegoArt.createdTime;
        blockNum = gegoArt.blockNum;
        tokenAmount = gegoArt.tokenAmount;
        tokenAddress = gegoArt.tokenAddress;
        author = gegoArt.author;
        resName = gegoArt.resName;
    }

    function mint(string memory resName, address to,  address tokenAddress, uint256 tokenAmount) public 
        nonReentrant
        returns (uint256) {
        require(_isUserStart || _minters[msg.sender]  , "can't mint");
        require(_resMap[resName] == address(0x0), "resName has existed");

        uint256 realAmount = 0;
        if( tokenAddress != address(0x0) ){
            require(tokenAmount > 0, "tokenAmount must > 0");

            IERC20 token = IERC20(tokenAddress);
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
            uint256 balanceEnd = token.balanceOf(address(this));
            realAmount = balanceEnd.sub(balanceBefore);

            _costToken.safeTransferFrom(msg.sender, _costAddress, _costAmount);
        }
        _gegoArtId++ ;

        GegoArt memory gegoArt;
        gegoArt.id = _gegoArtId;

        gegoArt.blockNum = block.number;
        gegoArt.createdTime =  block.timestamp ;
        gegoArt.tokenAddress = tokenAddress;
        gegoArt.tokenAmount = realAmount;
        gegoArt.author = to;
        gegoArt.resName = resName;

        _gegoArts[_gegoArtId] = gegoArt;

        _gegoArt.mint(to, _gegoArtId);
        _resMap[resName] = to;

        emit GegoArtAdded(
            gegoArt.id,
            gegoArt.blockNum,
            gegoArt.createdTime,
            gegoArt.tokenAmount,
            gegoArt.tokenAddress,
            gegoArt.author,
            gegoArt.resName
        );

        if(_hasReward){
            _rewardToken.mint(msg.sender, _rewardAmount); 
        }

        return _gegoArtId;
    }


    function burn(uint256 tokenId) 
        external nonReentrant
        returns ( bool ) {
        GegoArt memory gegoArt = _gegoArts[tokenId];
        require(gegoArt.id > 0, "not exist");

        if(!_minters[msg.sender]){
            require( (block.timestamp - gegoArt.createdTime) >= _burnTime, "< burnTime"  );
        }

        // transfer nft to contract
        _gegoArt.safeTransferFrom(msg.sender, address(this), tokenId);
        _gegoArt.burn(tokenId);

        if( gegoArt.tokenAddress != address(0x0) && gegoArt.tokenAmount > 0 ){
            IERC20 token = IERC20(gegoArt.tokenAddress);
            token.safeTransfer(msg.sender, gegoArt.tokenAmount);
        }

        _resMap[gegoArt.resName] = address(0x0);

        // set burn flag
        emit GegoArtBurn(gegoArt.id, gegoArt.tokenAddress, gegoArt.tokenAmount);
        gegoArt.id = 0;

        delete _gegoArts[tokenId];
        
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
