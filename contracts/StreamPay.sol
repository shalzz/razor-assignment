// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@nomiclabs/buidler/console.sol";

contract StreamPay {
  uint256 _remainingBalance;
  uint256 _deposit;
  uint256 _ratePerSecond;
  address _recipient;
  address _sender;
  uint256 _startTime;
  uint256 _stopTime;

  event WithdrawFromStream(address recipient, uint256 amount);

  function createStream(
    address recipient,
    uint256 deposit,
    uint256 startTime,
    uint256 stopTime
  ) public payable {
    require(recipient != address(0x00), "stream to the zero address");
    require(recipient != address(this), "stream to the contract itself");
    require(recipient != msg.sender, "stream to the caller");
    require(deposit > 0, "deposit is zero");
    require(startTime >= block.timestamp, "start time before block.timestamp");
    require(stopTime > startTime, "stop time before the start time");
    require(
      deposit == msg.value,
      "The required deposit amount is not transfered to the contract"
    );

    uint256 duration;
    uint256 ratePerSecond;
    duration = SafeMath.sub(stopTime, startTime);

    /* Without this, the rate per second would be zero. */
    require(deposit >= duration, "deposit smaller than time delta");

    /* This condition avoids dealing with remainders */
    require(deposit % duration == 0, "deposit not multiple of time delta");

    ratePerSecond = SafeMath.div(deposit, duration);

    /* Create and store the stream object. */
    _remainingBalance = deposit;
    _deposit = deposit;
    _ratePerSecond = ratePerSecond;
    _recipient = recipient;
    _sender = msg.sender;
    _startTime = startTime;
    _stopTime = stopTime;
  }

  function withdrawFromStream() public {
    uint256 balance = balanceOf(_recipient);
    require(balance > 0, "No balance to withdraw yet.");
    console.log(balance);

    _remainingBalance = SafeMath.sub(_remainingBalance, balance);

    emit WithdrawFromStream(_recipient, balance);
    payable(_recipient).transfer(balance);
  }

  function balanceOf(address who) public view returns (uint256 balance) {
    uint256 delta = deltaOf();
    uint256 recipientBalance = SafeMath.mul(delta, _ratePerSecond);

    /*
     * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
     * We have to subtract the total amount withdrawn from the amount of money that has been
     * streamed until now.
     */
    if (_deposit > _remainingBalance) {
      uint256 withdrawalAmount = SafeMath.sub(_deposit, _remainingBalance);
      recipientBalance = SafeMath.sub(recipientBalance, withdrawalAmount);
    }

    if (who == _recipient) return recipientBalance;
    if (who == _sender) {
      uint256 senderBalance = SafeMath.sub(_remainingBalance, recipientBalance);
      return senderBalance;
    }
  }

  function deltaOf() public view returns (uint256 delta) {
    if (block.timestamp <= _startTime) return 0;
    if (block.timestamp < _stopTime) return block.timestamp - _startTime;
    return _stopTime - _startTime;
  }
}
