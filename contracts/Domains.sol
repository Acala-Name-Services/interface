// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
// We import another help function
import {Base64} from "./libraries/Base64.sol";

contract Domains is ERC721URIStorage, ERC721Enumerable {
    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld = "acala";

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="128.000000pt" height="128.000000pt" viewBox="0 0 128.000000 128.000000" preserveAspectRatio="xMidYMid meet"><g transform="translate(0.000000,128.000000) scale(0.100000,-0.100000)" fill="#000000" stroke="none"><path d="M560 1270 c-142 -18 -255 -74 -366 -185 -66 -65 -89 -96 -122 -165 -51 -108 -66 -172 -65 -285 1 -204 91 -384 251 -505 335 -252 819 -113 975 281 176 443 -194 917 -673 859z m224 -66 c200 -51 369 -220 421 -420 19 -75 19 -213 0 -289 -53 -204 -224 -372 -426 -420 -375 -88 -739 214 -716 595 7 113 37 203 98 295 79 118 205 207 337 239 78 19 211 19 286 0z"/><path d="M512 1156 c-187 -46 -352 -216 -391 -404 -58 -280 112 -556 384 -627 180 -47 378 7 510 140 208 208 208 544 0 750 -131 130 -324 184 -503 141z m253 -58 c64 -16 155 -69 207 -121 92 -92 138 -202 138 -333 0 -144 -49 -256 -156 -353 -233 -213 -603 -136 -741 154 -31 66 -37 89 -41 170 -4 75 -1 106 16 161 75 247 323 385 577 322z"/><path d="M631 978 c27 -52 292 -514 299 -522 5 -4 15 5 23 20 15 29 13 32 -128 274 -136 234 -143 245 -174 248 -31 3 -32 2 -20 -20z"/> <path d="M449 758 c-67 -117 -128 -222 -135 -233 -11 -17 -11 -25 5 -48 l18 -27 117 205 c65 113 121 205 124 205 7 0 142 -232 142 -244 0 -3 -25 -3 -56 0 -52 7 -58 5 -75 -17 -10 -13 -19 -27 -19 -31 0 -5 28 -8 63 -8 108 0 131 -12 173 -85 33 -60 38 -65 70 -65 l33 0 -85 148 c-47 81 -120 207 -163 279 -42 73 -79 133 -83 133 -3 0 -61 -96 -129 -212z"/><path d="M473 600 c-57 -98 -103 -180 -103 -184 0 -13 61 -5 109 14 67 26 165 35 231 21 29 -6 55 -9 57 -7 3 2 -2 17 -11 34 -13 26 -22 30 -67 34 -29 3 -86 2 -128 -3 -41 -5 -76 -7 -77 -6 -1 1 27 51 62 112 35 60 64 112 64 115 0 3 -8 15 -18 27 -17 21 -18 19 -119 -157z"/></g></svg></defs><text x="32.5" y="231" font-size="';

    string svgPartTwo = '" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartThree = "</text></svg>";

    mapping(string => address) public domains;
    mapping(uint256 => string) public tokenIdToName;
    mapping(string => Record) public records;

    struct Record {
        address addressMetamask;
        address addressAcala;
        uint expiry;
    }

    address payable public owner;
    event Register(uint256 indexed tokenId, address owner, string name);

    constructor()
        payable
        ERC721("Acala Name Services", "ANS")
    {
        owner = payable(msg.sender);
    }

    function register(string calldata name) public payable {
        require(domains[name] == address(0));

        uint256 _price = price(name);
        uint256 _fontSize = fontSize(name);
        require(msg.value >= _price, "Not enough Acala paid");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne,_fontSize, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the Acala Name Services", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        tokenIdToName[newRecordId] = name;
        domains[name] = msg.sender;
        records[name].expiry = block.timestamp + 365 days;
        _tokenIds.increment();
        emit Register(newRecordId, msg.sender, name);
    }

    function setRecord(string calldata name, address addressMetamask, address addressAcala) public {
        // Check that the owner is the transaction sender
        require(domains[name] == msg.sender);
        require(addressMetamask != address(0) && addressAcala != address(0));
        records[name].addressMetamask = addressMetamask;
        records[name].addressAcala = addressAcala;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        domains[tokenIdToName[tokenId]] = to;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len <= 3) {
            return 100 * 10**18;
        } else if (len == 4) {
            return 70 * 10**18;
        } else {
            return 1 * 10**18;
        }
    }

    // This function will give us the length of a domain based on length
    function fontSize(string calldata name) private pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len <= 3) {
            return 40;
        } else if (len >= 4 && len <= 10) {
            return 24;
        } else {
            return 15;
        }
    }

    // Other functions unchanged
    function getAddress(string calldata name) public view returns (address) {
        // Check that the owner is the transaction sender
        return domains[name];
    }

    function getRecord(string calldata name) public view returns (Record memory) {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Acala");
    }
}