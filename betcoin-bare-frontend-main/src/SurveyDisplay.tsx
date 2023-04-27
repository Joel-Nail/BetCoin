import React, { useEffect, useState } from 'react';
import Web3 from 'web3';
import PollBetJson from '~/PollBetContract.json';

const betcoin_json_interface = PollBetJson;
const betcoin_address = "";

type PollInfo = {
    pollId: number,
    pollAddress: string,
    startTime: number,
    endTime: number,
    choices: [],
    isOver: boolean,
    selectedOption: number
}

class SurveyDisplay extends React.Component<{}, PollInfo> {
    constructor(info: PollInfo) {

        super(info);

        this.state = info;

        this.onValueChange = this.onValueChange.bind(this);
        this.formSubmit = this.formSubmit.bind(this);
    }


    onValueChange(event: React.ChangeEvent<HTMLInputElement>) {
        this.setState({
            ...this.state,
            selectedOption: +event.target.value,
        });
    }


    formSubmit(event: { preventDefault: () => void; }) {
        event.preventDefault();
        console.log(this.state.selectedOption)
        // Send the transaction!
    }

    render() {

        return (

            <form onSubmit={this.formSubmit}>
                <div className="radio">
                    <label>
                        <input
                            type="radio"
                            value="1"
                            checked={this.state.selectedOption === 1}
                            onChange={this.onValueChange}
                        />
                        Option 1
                    </label>
                </div>
                <div className="radio">
                    <label>
                        <input
                            type="radio"
                            value="2"
                            checked={this.state.selectedOption === 2}
                            onChange={this.onValueChange}
                        />
                        Option 2
                    </label>
                </div>
                <div className="radio">
                    <label>
                        <input
                            type="radio"
                            value="3"
                            checked={this.state.selectedOption === 3}
                            onChange={this.onValueChange}
                        />
                        Option 3
                    </label>
                </div>
                <div>
                    Selected option is : {this.state.selectedOption}
                </div>
                    <button className="btn btn-default" type="submit">
                        Submit
                    </button>
                </form>
            );
    }
}

export default SurveyDisplay;