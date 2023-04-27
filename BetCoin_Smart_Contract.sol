// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// TO DO
// 1. Add comments
// 2. Modify contents of events and emit events after relevant functions
// 3. Change accessibility of functions that need to be private

// the BetCoin contract contains all code to enable the creation of polls, voting on polls, and betting on those polls
contract BetCoin {

    // used to count the number of voters on a poll
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Poll {
        uint id;
        address creator;
        uint startTime;
        uint endTime;
        string[] choices;
        uint[] choiceCounts;
        bool isOpen;
        uint winningChoice;
    }

    struct Voter {
        uint pollId;
        address voterAddress;
        uint choice;
    }

    struct Bet {
        uint pollId;
        uint pollChoice;
        address payable user;
        uint amount;
    }

    // Events
    event PollCreated(uint indexed id, address indexed creator, uint startTime, uint endTime, string[] options);
    event PollClosed(uint indexed id, uint indexed winner);
    event BetPlaced(uint indexed pollId, string pollChoice, address indexed user, uint amount);
    // NEED TO UPDATE
    event RewardsDistributed(uint indexed pollId, address payable[] winners, uint[] rewards);
    
    // need to change so that the choice is not published when this event is emitted 
    event VoteCasted(uint indexed pollId, address indexed voter, uint choice);
    
    event Log(string message);


    // Variables
    uint public pollCount;
    uint public betCount;
    // mapping - to store data on blockchain
    mapping(uint => uint) public pollBetTotal;
    mapping(uint => mapping(address => uint)) public pollBets;
    mapping(uint => uint[]) public pollWinners;
    mapping(address => uint) public balances;
    mapping(uint => Bet[]) public pollBetsList;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => mapping(address => Voter)) public voters;
    mapping(uint => EnumerableSet.AddressSet) internal voterAddressSets;

    //Poll[] public polls;
    mapping(uint => Poll) polls; // change to mapping
    uint[] public pollCounts;

    // function to create a poll with multiple poll choices
    function createPoll(uint _startTime, uint _endTime, string[] memory _options) public {
        _startTime = block.timestamp; // default for MVP - should be customizable
        _endTime = block.timestamp + 86400; // default for MVP - should be customizable
        
        // cannot schedule poll to end before it begins
        require(_endTime > _startTime, "Invalid poll end time");
        // must provide at least two choices (not including the poll prompt)
        require(_options.length > 1, "At least two options required");

        // numChoices = number of poll choices (does not include the poll prompt itself)
        uint numChoices; 
        numChoices = _options.length;

        // create array with dyanmic amount of 0s depending on number of choices entered by user 
        uint[] memory choiceCountsArray = new uint[](numChoices);

        // create new poll using Poll struct
        Poll storage newPoll = polls[pollCount];
        // add info to poll
        newPoll.creator = msg.sender;
        newPoll.startTime = block.timestamp;
        newPoll.endTime = block.timestamp + 86400;
        newPoll.choices = _options;
        newPoll.choiceCounts = choiceCountsArray;
        newPoll.isOpen = true;
        // add new poll to list of polls
        pollCounts.push(pollCount);

        // emit PollCreated event
        emit PollCreated(pollCount, msg.sender, _startTime, _endTime, _options);

        pollCount++; // increment poll count i.e., pollId
        
    }

    function getPollVotersCount(uint _pollId) public view returns (uint) {
        uint count = 0;
        EnumerableSet.AddressSet storage voterAddresses = voterAddressSets[_pollId];

        for (uint i = 0; i < EnumerableSet.length(voterAddresses); i++) {
            count++;
        }

        return count;
    }

        // function to return the prompt for a poll i.e., index 0 in the choices variable 
    function getPollPrompt(uint _pollId) public view returns (string memory){
        // access the poll input by the user
        Poll storage poll = polls[_pollId];
        
        // access the choices array for the poll input by the user
        string[] memory pollChoices = poll.choices;

        // return the poll prompt which is the 0th index in the choices array
        return pollChoices[0]; 
    }

    // return the voting choices for a poll (i.e., only the things you can vote for, not the prompt)
    function getPollChoices(uint _pollId) public view returns (string[] memory) {
        // access poll input by user
        Poll storage poll = polls[_pollId];

        // access the choices variable for the poll input by the user
        string[] memory pollChoicesVar = poll.choices;
        
        // create a new array to contain only the voting choices for a poll
        string[] memory pollChoicesOnly = new string[](poll.choices.length-1);

        // add only the voting choices to the newly created array
        for (uint i = 1; i < poll.choices.length; i++) {
            pollChoicesOnly[i-1] = (pollChoicesVar[i]);
        }

        return pollChoicesOnly; 
    }

    // must be PRIVATE in final implementation
    function getPollChoiceCounts(uint _pollId) public view returns (uint[] memory){
        // access the poll input by the user
        Poll storage poll = polls[_pollId];
        
        // access the choice counts variable for the poll input by the user
        uint[] memory pollChoiceCountsVar = poll.choiceCounts;
        
        // create a new array to contain only the voting choice counts for a poll
        uint[] memory pollChoiceCountsOnly = new uint[](poll.choices.length-1);

        // add only the voting choice counts to the newly created array
        for (uint i = 1; i < poll.choiceCounts.length; i++) {
            pollChoiceCountsOnly[i-1] = (pollChoiceCountsVar[i]);
        }

        // return the poll prompt which is the 0th index in the choices array
        return pollChoiceCountsOnly; 
    }


    function voteOnPoll(uint _pollId, uint _pollChoice) public {
        // access relevant poll
        Poll storage poll = polls[_pollId];
        
        //require(!hasVoted[_pollId][msg.sender], "Already voted"); REIMPLEMENT AFTER TESTING
        require(poll.isOpen, "Poll is closed");
        require(block.timestamp >= poll.startTime && block.timestamp <= poll.endTime, "Poll is not active");
        require(_pollChoice > 0 && _pollChoice < poll.choices.length, "Invalid choice");

        hasVoted[_pollId][msg.sender] = true;

        Voter memory newVoter = Voter({
            pollId: _pollId,
            voterAddress: msg.sender,
            choice: _pollChoice
        });
        voters[_pollId][msg.sender] = newVoter;
        addVoterAddressSet(_pollId,msg.sender);

        // increase the choiceCount variable for the choice that was voted on
        poll.choiceCounts[_pollChoice]++;

        emit VoteCasted(_pollId, msg.sender, _pollChoice);
    }

    function betOnPoll(uint _pollId, uint _pollChoice) public payable { // Data location must be "memory" or "calldata" for parameter in function, but none was given
        require(block.timestamp >= polls[_pollId].startTime, "Poll has not started yet, you cannot bet on it");
        require(block.timestamp < polls[_pollId].endTime, "Poll has ended, you cannot bet on it anymore");
        require(msg.value > 0, "Amount must be greater than 0!");
        // Convert poll choice to uint
        //uint pollChoiceInt;
        /*for (uint i = 0; i < polls[_pollId].choices.length; i++) {
            if (keccak256(bytes(polls[_pollId].choices[i])) == _pollChoice) {
                pollChoiceInt = i;
                break;
            }
        }*/
        require(_pollChoice > 0, "Invalid poll choice, please select one of the poll choices to bet on");
        pollBetTotal[_pollId] += msg.value;
        pollBets[_pollId][msg.sender] += msg.value;
        betCount++;
        pollBetsList[_pollId].push(Bet({
            pollId: _pollId,
            //pollChoice: polls[_pollId].choices[_pollChoice],
            pollChoice: _pollChoice,
            user: payable(msg.sender),
            amount: msg.value
        }));
        emit BetPlaced(_pollId, polls[_pollId].choices[_pollChoice], msg.sender, msg.value);
    }

    function getBetCount(uint _pollId) public view returns(uint) {
        return pollBetsList[_pollId].length;
    }

    function getTotalBetAmount(uint _pollId) public view returns(uint) {
        uint totalBetAmount = 0;
        for (uint i = 0; i < pollBetsList[_pollId].length; i++) {
            totalBetAmount += pollBetsList[_pollId][i].amount;
        }
        return totalBetAmount;
    }

    function getChoiceBetAmount(uint _pollId, uint _pollChoice) public view returns(uint){
        uint choiceBetAmount = 0;
        Bet[] storage bets = pollBetsList[_pollId];
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _pollChoice) {
                choiceBetAmount += bets[i].amount;
            }
        }
        
        return choiceBetAmount;
    }

    function getChoiceBetPercent(uint _pollId, uint _pollChoice) public view returns(uint){
        uint choiceBetPercent;
        
        uint choiceBetAmount = getChoiceBetAmount(_pollId, _pollChoice);
        uint totalBetAmount = getTotalBetAmount(_pollId);

        if (totalBetAmount != 0){
            choiceBetPercent = (choiceBetAmount * 10000) / (totalBetAmount * 100);
        }
        if (totalBetAmount == 0){
            choiceBetPercent = 0;
        }
    
        return choiceBetPercent;
    }

//    function getOdds(uint _pollId, uint _pollChoice) public view returns(uint){
//
//        uint totalChoiceAmount = 0;
//        Bet[] storage bets = pollBetsList[_pollId];
//        for (uint i = 0; i < bets.length; i++) {
//            if (bets[i].pollChoice == _pollChoice) {
//                totalChoiceAmount += bets[i].amount;
//            }
//        }
//        uint totalBetAmount = getTotalBetAmount(_pollId);
//        uint choiceBetFrac = totalChoiceAmount / totalBetAmount * 100;
//        return choiceBetFrac;
//        //return totalBetAmount > 0 ? totalChoiceAmount / totalBetAmount : 0;
//    }

    function closePoll(uint _pollId) public payable returns(uint[] memory, uint[] memory, uint[] memory) {
        Poll storage poll = polls[_pollId];

        uint winningPoll = 0;

        uint[] memory pollChoiceCounts = poll.choiceCounts;
        // check count of votes on each choice - highest number of votes will be winner
        // NEED TO ADD CODE WITH WHAT TO DO IN CASE OF A TIE
        for (uint i = 1; i < poll.choiceCounts.length; i++){
            if (pollChoiceCounts[i] > pollChoiceCounts[winningPoll]) {
                winningPoll = i;
            }
        }

        poll.isOpen = false;
        emit PollClosed(_pollId, winningPoll); //publish to blockchain

        // CALL DISTRIBUTE REWARDS HERE
        (uint[] memory winningBets, uint[] memory winningBetWinnings, uint[] memory winningBetAmounts) = distributeRewards(_pollId, winningPoll);

        return (winningBets, winningBetAmounts, winningBetWinnings);
    } 

    // THIS SHOULD BE PRIVATE INSTEAD OF PUBLIC
    function distributeRewards(uint _pollId, uint _winningPollChoice) public payable returns(uint[] memory, uint[] memory, uint[] memory){
        Bet[] storage bets = pollBetsList[_pollId];

        uint numWinningBets = 0;

        // first, get number of winning bets
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                numWinningBets += 1;
            }
        }

        uint[] memory winningBets = new uint[](numWinningBets);
        
        uint winningBetIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                winningBets[winningBetIdx] = i;
                winningBetIdx += 1;
            }
        }

        // for now, we just split the total bet amount equally between winners
        // NEED TO CALCULATE PROPER AMOUNT TO DISTRIBUTE TO EACH USER
        // uint totalBetAmount = getTotalBetAmount(_pollId);
        // uint betWinningsDivided = totalBetAmount / winningBets.length;

        (uint[] memory winningBetWinnings, uint[] memory winningBetAmounts) = calculateWinnings(_pollId, _winningPollChoice, winningBets);

        uint winningBetWinningsIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                bets[i].user.transfer(winningBetWinnings[winningBetWinningsIdx]);
                winningBetWinningsIdx += 1;
            }
        }
        
        return (winningBets, winningBetWinnings, winningBetAmounts); // currently just returns the indexes of winning bets - need to update
        // NEED TO EMIT UPDATED EVENT WITH INFO ON DISTRIBUTED REWARDS

    }

    function calculateWinnings(uint _pollId, uint _winningPollChoice, uint[] memory _winningBets) public view returns(uint[] memory, uint[] memory){
        Bet[] storage bets = pollBetsList[_pollId];

        uint totalBetAmount = getTotalBetAmount(_pollId);

        uint[] memory winningBetAmounts = new uint[](_winningBets.length);
        uint totalWinningBetAmounts = 0;
        
        uint winningBetAmountsIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                winningBetAmounts[winningBetAmountsIdx] = bets[i].amount;
                totalWinningBetAmounts += bets[i].amount;
                winningBetAmountsIdx += 1;
            }
        }

        uint[] memory winningBetWinnings = new uint[](_winningBets.length);

        uint winningBetWinningsIdx = 0;
        for (uint i = 0; i < winningBetAmounts.length; i++){
            winningBetWinnings[winningBetWinningsIdx] = ((winningBetAmounts[i]*10000 / totalWinningBetAmounts)*totalBetAmount)/10000;
            winningBetWinningsIdx += 1;
        }

        return (winningBetWinnings, winningBetAmounts);
    }

    
    
    
    











    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < bytesArray.length; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function addVoterAddressSet(uint _pollId, address _voterAddress) private {
        voterAddressSets[_pollId].add(_voterAddress);
    }

}