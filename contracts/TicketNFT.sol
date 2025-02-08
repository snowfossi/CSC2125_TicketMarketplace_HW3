// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)
    // state variables
    address private ct_owner;

    // constructor
    constructor() ERC1155("") {
        ct_owner = msg.sender;
    }

    // mintFromMarketPlace
    
    function mintFromMarketPlace(address to, uint256 nftId) external override {
        // from ERC1155
        _mint(to, nftId, 1, "");
    }

    // return owner of the NFT contract
    function owner() public view returns (address) {
        return ct_owner;
    }

}

