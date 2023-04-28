// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


/**********************************************************************************************************/

// TO-DO
// 1. Add comments
// 2. Modify contents of events and emit events after relevant functions
// 3. Change accessibility of functions that need to be private
// 4. Test all functions to ensure reliable performance
// 5. Improve logic used to calculate and distribute winnings (use something other than array indexes)
// 6. Refactor code to ensure consistency among variable names
// 7. Modify Poll structure and createPoll function so that poll prompt is separate from poll choices

/**********************************************************************************************************/


// the BetCoin contract contains all code to enable the creation of polls, voting on polls, and betting on those polls
contract BetCoin {

    // DATA STRUCTURES
    
    // used to track poll voters by address
    using EnumerableSet for EnumerableSet.AddressSet;

    // data structure for polls - an instance of this struct is created each time the createPoll function is triggered
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

    // data structure for voters - an instance of this struct is created each time the voteOnPoll function is triggered
    struct Voter {
        uint pollId;
        address voterAddress; // TO-DO: needs to be payable in order to give users incentives for voting
        uint choice;
    }

    // data structure for bets - an instance of this struct is created each time the betOnPoll function is triggered
    struct Bet {
        uint pollId;
        uint pollChoice;
        address payable user;
        uint amount;
    }

    /*******************************************************************************************************************************/
   
    // EVENTS
    // TO-DO: NEED TO UPDATE EVENTS AND ENSURE THEY ARE EMITTED WITHIN CORRECT FUNCTIONS

    // event to be emitted whenever a user creates a poll
    event PollCreated(uint indexed id, address indexed creator, uint startTime, uint endTime, string[] options);

    // event to be emitted whenever a poll reaches its end time
    event PollClosed(uint indexed id, uint indexed winner);

    // event to be emitted whenever a bet is placed on a poll
    event BetPlaced(uint indexed pollId, string pollChoice, address indexed user, uint amount);

    // event to be emitted whenever a poll is closed and rewards are distributed to winning bettors
    event RewardsDistributed(uint indexed pollId, address payable[] winners, uint[] rewards);

    // TO-DO: need to change so that the choice is not published when this event is emitted 
    // event to be emitted whenever a poll is voted on
    event VoteCasted(uint indexed pollId, address indexed voter, uint choice);

    // generic event - not used in current code
    event Log(string message);

    /*******************************************************************************************************************************/

    // VARIABLES AND MAPPINGS
    // TO-DO: REASSESS MAPPINGS AND ENSURE EVERYTHING IS USED AS IT SHOULD BE

    // global variable to track the number of polls that have been created
    uint public pollCount;

    // global variable to track the number of bets that have been created
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
    mapping(uint => Poll) polls;
    uint[] public pollCounts;

    /*******************************************************************************************************************************/

    // FUNCTIONS

    // function to create a poll with multiple poll choices
    function createPoll(uint _startTime, uint _endTime, string[] memory _options) public {
        _startTime = block.timestamp; // default for PoC - should be customizable
        _endTime = block.timestamp + 86400; // default for PoC - should be customizable
        
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

    
    // function to return number of voters on a poll 
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

    
    // function to return the number of votes cast for each voting choice of a poll
    // TO-DO: must be made PRIVATE in final implementation
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

        return pollChoiceCountsOnly; 
    }


    // function to cast a vote for a voting choice of a poll
    function voteOnPoll(uint _pollId, uint _pollChoice) public {
        // access relevant poll
        Poll storage poll = polls[_pollId];
        
        // TO-DO: uncomment this requirement after testing
        //require(!hasVoted[_pollId][msg.sender], "Already voted"); // users can only vote on a poll once
        require(poll.isOpen, "Poll is closed"); // poll must be open in order to vote on it
        require(block.timestamp >= poll.startTime && block.timestamp <= poll.endTime, "Poll is not active"); // ensures that votes are only made between start and end time
        require(_pollChoice > 0 && _pollChoice < poll.choices.length, "Invalid choice"); // can only vote for the voting choices available for the selected poll

        hasVoted[_pollId][msg.sender] = true; // records the current user as having voted on the poll

        // create a Voter data structure for current voter
        Voter memory newVoter = Voter({
            pollId: _pollId,
            voterAddress: msg.sender,
            choice: _pollChoice
        });

        voters[_pollId][msg.sender] = newVoter; // add voter to list of voters
        addVoterAddressSet(_pollId,msg.sender); // add voter's address to list of voter addresses

        // increase the choiceCount variable for the choice that was voted on
        poll.choiceCounts[_pollChoice]++;

        emit VoteCasted(_pollId, msg.sender, _pollChoice);
    }

    
    // function to allow users to bet on a poll
    function betOnPoll(uint _pollId, uint _pollChoice) public payable { 
        require(block.timestamp >= polls[_pollId].startTime, "Poll has not started yet, you cannot bet on it");
        require(block.timestamp < polls[_pollId].endTime, "Poll has ended, you cannot bet on it anymore");
        require(msg.value > 0, "Amount must be greater than 0!");
        require(_pollChoice > 0, "Invalid poll choice, please select one of the poll choices to bet on");

        pollBetTotal[_pollId] += msg.value; // increase Bet Total for poll by amount the current user bet
        pollBets[_pollId][msg.sender] += msg.value; // add amount bet by current user to list of poll bets
        betCount++; // increment bet count by one
        
        // push info about current bettor to list of poll bets
        pollBetsList[_pollId].push(Bet({
            pollId: _pollId,
            pollChoice: _pollChoice,
            user: payable(msg.sender),
            amount: msg.value
        }));

        emit BetPlaced(_pollId, polls[_pollId].choices[_pollChoice], msg.sender, msg.value);
    }

    
    // function to return the number of bets on a poll
    function getBetCount(uint _pollId) public view returns(uint) {
        return pollBetsList[_pollId].length;
    }

    
    // function to return the total amount of money bet on a poll
    function getTotalBetAmount(uint _pollId) public view returns(uint) {
        uint totalBetAmount = 0;
        for (uint i = 0; i < pollBetsList[_pollId].length; i++) {
            totalBetAmount += pollBetsList[_pollId][i].amount;
        }
        return totalBetAmount;
    }

    
    // function to return the total amount of money bet on a certain voting choice on a poll
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

    
    // function to return the percent of the total bet amount that a single voting choice makes up
    // can be used to display odds on platform before users bet
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


    // function to close a poll and distribute rewards to the winning bettors 
    function closePoll(uint _pollId) public payable returns(uint[] memory, uint[] memory, uint[] memory) {
        Poll storage poll = polls[_pollId]; // access poll to be closed

        // code to check count of votes on each choice - highest number of votes will be winner
        // TO-DO: NEED TO ADD CODE WITH WHAT TO DO IN CASE OF A TIE
        uint winningPoll = 0; // default variable - will be used to determine the winning poll voting choice
        uint[] memory pollChoiceCounts = poll.choiceCounts; // list of votes cast for each poll votin choice
        // finds the voting choice with the highest number of votes and sets winningPoll variable equal to that voting choice's index
        for (uint i = 1; i < poll.choiceCounts.length; i++){
            if (pollChoiceCounts[i] > pollChoiceCounts[winningPoll]) {
                winningPoll = i;
            }
        }

        poll.isOpen = false; // close poll

        emit PollClosed(_pollId, winningPoll);

        // Distribute the proper amount of winnings to poll bettors and return data about winning bets
        (uint[] memory winningBets, uint[] memory winningBetWinnings, uint[] memory winningBetAmounts) = distributeRewards(_pollId, winningPoll);
        return (winningBets, winningBetAmounts, winningBetWinnings);
    } 

    
    // function to distribute the proper amount of winnings to poll bettors
    // TO-DO: THIS SHOULD BE PRIVATE INSTEAD OF PUBLIC
    function distributeRewards(uint _pollId, uint _winningPollChoice) public payable returns(uint[] memory, uint[] memory, uint[] memory){
        Bet[] storage bets = pollBetsList[_pollId]; // access bets for the given poll

        uint numWinningBets = 0; // will be used to hold the number of winning bets for a poll
        // first, get number of winning bets
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                numWinningBets += 1;
            }
        }

        // next we iterate through the list of bets to find the winning bets
        uint[] memory winningBets = new uint[](numWinningBets);
        uint winningBetIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                winningBets[winningBetIdx] = i;
                winningBetIdx += 1;
            }
        }

        // call calculate winnings to determine the winnings for each winning bet 
        (uint[] memory winningBetWinnings, uint[] memory winningBetAmounts) = calculateWinnings(_pollId, _winningPollChoice, winningBets);

        // transfer the proper amounts of winnings to each user who made a winning bet
        uint winningBetWinningsIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                bets[i].user.transfer(winningBetWinnings[winningBetWinningsIdx]);
                winningBetWinningsIdx += 1;
            }
        }
        
        // return three arrays: a list of winnings bets, a list of the winnings for each bet, and a list of the original bet amount for those bets
        return (winningBets, winningBetWinnings, winningBetAmounts); 
        // TO-DO: NEED TO EMIT UPDATED EVENT WITH INFO ON DISTRIBUTED REWARDS

    }

    
    // function to calculate the proper amount of winnings for each winning bet on a poll
    function calculateWinnings(uint _pollId, uint _winningPollChoice, uint[] memory _winningBets) public view returns(uint[] memory, uint[] memory){
        Bet[] storage bets = pollBetsList[_pollId]; // access the bets for the given poll

        uint totalBetAmount = getTotalBetAmount(_pollId); // get total amount of money bet on the poll

        uint[] memory winningBetAmounts = new uint[](_winningBets.length);
        uint totalWinningBetAmounts = 0; // this will be the amount of money bet on winning bets
        
        // iterate through the list of bets to create a list of winning bet amounts + a variable with the total amount of all winning bets
        uint winningBetAmountsIdx = 0;
        for (uint i = 0; i < bets.length; i++){
            if (bets[i].pollChoice == _winningPollChoice) {
                winningBetAmounts[winningBetAmountsIdx] = bets[i].amount;
                totalWinningBetAmounts += bets[i].amount;
                winningBetAmountsIdx += 1;
            }
        }

        uint[] memory winningBetWinnings = new uint[](_winningBets.length); // array that will contain how much each bet should receive in winnings

        // iterate through the list of winning bets to calculate how much the bettor should be awarded in winnings
        // we calculate this as (bettor's % of winning bet amounts) * (total amount of money bet on poll)
        uint winningBetWinningsIdx = 0;
        for (uint i = 0; i < winningBetAmounts.length; i++){
            winningBetWinnings[winningBetWinningsIdx] = ((winningBetAmounts[i]*10000 / totalWinningBetAmounts)*totalBetAmount)/10000;
            winningBetWinningsIdx += 1;
        }

        return (winningBetWinnings, winningBetAmounts); // return winnings for each bet + the original bet amount for each bet
    }

    
    // old function that is no longer used - converts a bytes32 variable to a string variable
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

    
    // adds a voter's address to a list of voter addresses
    function addVoterAddressSet(uint _pollId, address _voterAddress) private {
        voterAddressSets[_pollId].add(_voterAddress);
    }

}