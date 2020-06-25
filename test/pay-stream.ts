import {web3, artifacts, assert, contract} from "@nomiclabs/buidler";
import {StreamPayContract, StreamPayInstance} from "../types/truffle-contracts";

const StreamPay: StreamPayContract = artifacts.require("StreamPay");

describe("Stream Pay contract", function () {
  let accounts;
  let contract: StreamPayInstance;

  let owner: string;
  let otherUser: string;

  before(async function () {
    accounts = await web3.eth.getAccounts();
    owner = accounts[0];
    otherUser = accounts[1];

    contract = await StreamPay.new();
  });

  describe("Stream Pay", function () {
    it("Should create a payment stream", async function () {
      const block = await web3.eth.getBlock("latest");
      const deposit = web3.utils.toWei('36', "ether");
      const startTime = block.timestamp + 3600; // start after the current block
      const stopTime = startTime + 3600; // time period of 1 minute.
      await contract.createStream(otherUser, deposit, startTime, stopTime, {
        from: owner,
        value: deposit,
      });
    });

    it("Should be able to withdraw payment", function (done) {
      web3.currentProvider.send(
        {
          method: "evm_increaseTime",
          params: [3599 + 1800],
        },
        async () => {
          const prevBal = await web3.eth.getBalance(otherUser);

          const tx = await contract.withdrawFromStream({from: otherUser});
          const newBal = await web3.eth.getBalance(otherUser);
          console.log(newBal - prevBal);
          assert.isAbove(newBal - prevBal, 0);
          done();
        }
      );
    });
  });
});
