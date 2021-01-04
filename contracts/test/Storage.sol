pragma solidity ^0.5.0;


contract Storage {
    uint256 public val;
    // --- Data ---
    bool private initialized; // Flag of initialize data
    address public _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }

    constructor(uint256 v) public {
        val = v;
        _governance = tx.origin;
    }

    // --- Init ---
    function initialize(
        uint256 value
    ) public {
        require(!initialized, "initialize: Already initialized!");
        _governance = msg.sender;
        val = value;
        initialized = true;
    }


    function setValue(uint256 v) public {
        val = v;
    }

    function setMultiValue(uint256 v) public  onlyGovernance{
        val = 2*v;
    }

    function getValue() public view returns ( uint){
        return val;
    }
}
