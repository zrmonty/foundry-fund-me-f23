// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToBeFunded;
    address[] private s_funders;

    uint256 public constant MINIMUM_USD = 5e18;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToBeFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToBeFunded[funder] = 0;
        }

        s_funders = new address[](0);
        // msg.sender = address
        // payable(msg.sender) is type payable address (typecasting)
        // Transfer
        // payable(msg.sender.transfer(address(this).balance));
        // send
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Send failed");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == "i_owner", "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address addressToBeFunded
    ) external view returns (uint256) {
        return s_addressToBeFunded[addressToBeFunded];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
