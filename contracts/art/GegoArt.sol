pragma solidity ^0.5.5;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

import "../library/Governance.sol";
import "../library/DegoUtil.sol";


contract GegoArtToken is ERC721Full, Governance {
    // for minters
    mapping(address => bool) public _minters;

    constructor() public ERC721Full("gego.art", "GEGO-ART") {
        _setBaseURI("https://api.dego.finance/bsccommon/gego-art-token/");
    }


    function setURIPrefix( string memory baseURI) public onlyGovernance{
        _setBaseURI(baseURI);

    }


    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) external returns (bool) {
        require(_minters[msg.sender], "!minter");
        _mint(to, tokenId);
        _setTokenURI(tokenId, DegoUtil.uintToString(tokenId));
        return true;
    }

    /**
     * @dev Function to safely mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeMint(address to, uint256 tokenId) public returns (bool) {
        require(_minters[msg.sender], "!minter");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, DegoUtil.uintToString(tokenId));
        return true;
    }

    /**
     * @dev Function to safely mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @param _data bytes data to send along with a safe transfer check.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public returns (bool) {
        require(_minters[msg.sender], "!minter");
        _safeMint(to, tokenId, _data);
        _setTokenURI(tokenId, DegoUtil.uintToString(tokenId));
        return true;
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_minters[msg.sender], "!minter");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }


    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }


}
