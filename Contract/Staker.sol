// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 30 seconds;

    event Stake(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function execute() public notCompleted deadlineReached {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    function stake() public payable deadlineRemaining notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 userBalance = balances[msg.sender];
        require(timeLeft() == 0, "Deadline not yet expired");
        require(userBalance > 0, "No balance to withdraw");
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user balance back to the user");
    }

    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    modifier deadlineReached() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining == 0, "Deadline is not reached yet");
        _;
    }

    modifier deadlineRemaining() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining > 0, "Deadline is already reached");
        _;
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }
}
