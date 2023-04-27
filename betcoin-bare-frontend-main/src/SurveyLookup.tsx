import React, { useEffect, useState } from 'react';
import Web3 from 'web3';
import PollBetJson from '~/PollBetContract.json';

// JSON.parse(readFile)
const betcoin_json_interface = PollBetJson;
const betcoin_address = "0xc4750e70bd9B5357a125D6066a8fBE94B5Dff2Ee";

console.log(betcoin_json_interface)

const SurveyLookup: React.FC  = () => {

    const [pollId, setPollId] = useState<string>("");
    const Web3 = require('web3');
    // const web3 = new Web3(window.ethereum);
    const web3 = new Web3(Web3.givenProvider || "ws://172.31.65.226:3848");
    var Contract = require('web3-eth-contract');
    var contract = new Contract(betcoin_json_interface.abi, betcoin_address);

    const handleInputChange = (
        event: React.ChangeEvent<HTMLInputElement>
      ): void => {
        setPollId(event.target.value);
      };

    const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
        event.preventDefault();
        console.log(pollId);
        contract.methods.createPoll("1682289738", "1682289738", ["q1","a1","a2","a3"]).send({ from: "0x0000000000000000000000000000000000000011", gas: 0 }).then(console.log);
        // console.log(contract.methods.getPollInfo().send({id: pollId}));
        setPollId("");
    }

    return (
        <div className="p-1">
            <form onSubmit={ handleSubmit }>
                <input type="text" value={ pollId } onChange={ handleInputChange }/>
                <input type="submit" value="Fetch Survey"/>
            </form>
        </div>
    )
}

export default SurveyLookup;