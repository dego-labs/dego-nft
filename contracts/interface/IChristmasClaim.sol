pragma solidity ^0.5.0;


import "../interface/IGegoArtToken.sol";

interface IChristmasClaim {

    function burnWithdrawToken(address erc20, address owner, uint256 amount) external;

}