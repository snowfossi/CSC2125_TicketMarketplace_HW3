// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)
     // state variables
    address public owner;
    address public erc20Address;
    uint128 public currentEventId;
    ITicketNFT public ticketNFT;
    mapping(uint128 => EventData) public events;

    // about the event
    struct EventData {
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
        uint128 nextTicketToSell;
    }

    // constructor
    constructor(address input_erc20Address) {
        owner = msg.sender;
        erc20Address = input_erc20Address;
        ticketNFT = new TicketNFT();
    }

    // modifier to restrict access to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        // when override, continue from here
        _;
    }

    // event
    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override onlyOwner {
        events[currentEventId] = EventData(maxTickets, pricePerTicket, pricePerTicketERC20, 0);
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    // set max tickets
    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override onlyOwner {
        require(newMaxTickets > events[eventId].maxTickets, "The new number of max tickets is too small!");
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    // set the price wehn using erc20
    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override onlyOwner {
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    // set the price when using eth
    function setPriceForTicketETH(uint128 eventId, uint256 price) external override onlyOwner {
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    // change erc20 address
    function setERC20Address(address newERC20Address) external override onlyOwner {
        erc20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    // buy tickets using erc20
    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override {
        // overflow check
        require(events[eventId].pricePerTicketERC20 <= type(uint256).max / ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount > 0, "Ticket count should be greater than 0");
        require(ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");
        IERC20 erc20 = IERC20(erc20Address);
        uint256 totalAmount = events[eventId].pricePerTicketERC20 * ticketCount;
        require(erc20.allowance(msg.sender, address(this)) >= totalAmount, "Insufficient allowance");
        erc20.transferFrom(msg.sender, address(this), totalAmount);       
        events[eventId].maxTickets -= ticketCount;
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = (uint256(eventId) << 128) + events[eventId].nextTicketToSell;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
            events[eventId].nextTicketToSell++;
        }
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    // buy tickets using eth
    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override {
        // overflow check
        require(events[eventId].pricePerTicket <= type(uint256).max / ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(ticketCount > 0, "Ticket count should be greater than 0");
        require(ticketCount <= events[eventId].maxTickets, "We don't have that many tickets left to sell!");
        uint256 totalAmount = events[eventId].pricePerTicket * ticketCount;
        require(msg.value >= totalAmount, "Not enough funds supplied to buy the specified number of tickets.");
        events[eventId].maxTickets -= ticketCount;
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = (uint256(eventId) << 128) + events[eventId].nextTicketToSell;
            ticketNFT.mintFromMarketPlace(msg.sender, nftId);
            events[eventId].nextTicketToSell++;
        }
        emit TicketsBought(eventId, ticketCount, "ETH");
    }



    // return address of nft contract
    function nftContract() external view returns (address) {
        return address(ticketNFT);
    }

    // return address of erc20
    function ERC20Address() external view returns (address) {
        return erc20Address;
    }

}