pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;


import "../interface/IGegoArtToken.sol";

interface IGegoArtFactory {


    function getGegoArt(uint256 tokenId)
        external view
        returns (
            uint256 createdTime,
            uint256 blockNum,
            uint256 tokenAmount,
            address tokenAddress,
            address author,
            string memory resName
        );



    function burn(uint256 tokenId) external returns ( bool );

}