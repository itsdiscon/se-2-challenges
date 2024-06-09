// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(
      exampleExternalContractAddress
    );
  }

  bool public openForWithdraw = true;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;

  mapping(address => uint256) public balances;

  event Stake(address, uint256);

  modifier notCompleted() {
    require(
      exampleExternalContract.completed() == false,
      "Ya se transfirieron los fondos"
    );
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    require(msg.value > 0, "Usted no tiene fondos suficientes");
    require(block.timestamp < deadline, "El tiempo de deposito ya paso");

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    require(block.timestamp > deadline, "Aun no es tiempo de liberacion");

    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{ value: address(this).balance }();
      openForWithdraw = false;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notCompleted {
    require(openForWithdraw == true, "Los fondos fueron transferidos");
    require(address(this).balance < threshold, "El stake esta completo");
    require(balances[msg.sender] > 0, "Usted no tiene deposito");

    uint256 value = balances[msg.sender];

    balances[msg.sender] = 0;

    (bool response /*bytes memory data*/, ) = msg.sender.call{
      value: value
    }("");

    require(response, "transaccion fallida");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp <= deadline) {
      return deadline - block.timestamp;
    } else {
      return 0;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
   receive() external payable {
    stake();
  }
}