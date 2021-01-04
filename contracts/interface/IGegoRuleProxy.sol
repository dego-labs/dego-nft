pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;

import "../interface/IGegoToken.sol";


interface IGegoRuleProxy  {

    struct Cost721Asset{
        uint256 costErc721Id1;
        uint256 costErc721Id2;
        uint256 costErc721Id3;

        address costErc721Origin;
    }

    struct MintParams{
        address user;
        uint256 amount;
        uint256 ruleId;
    }

    function cost( MintParams calldata params, Cost721Asset calldata costSet1, Cost721Asset calldata costSet2 ) external returns (
        uint256 mintAmount,
        address mintErc20
    ) ;

    function destroy( address owner, IGegoToken.Gego calldata gego ) external ;

    function generate( address user,uint256 ruleId ) external view returns ( IGegoToken.Gego memory gego );

}