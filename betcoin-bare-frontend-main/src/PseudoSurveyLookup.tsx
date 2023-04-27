// import React, { useState, useEffect } from "react";
// import Web3 from "web3";
// import eth from "web3";

// type Survey = {
//   id: number;
//   question: string;
//   options: string[];
// };

// type SurveyProps = {
//   surveyId: number;
//   contractAddress: string;
// };

// const SurveyComponent: React.FC<SurveyProps> = ({
//   surveyId,
//   contractAddress,
// }) => {
//   const [survey, setSurvey] = useState<Survey | null>(null);

//   useEffect(() => {
//     const provider = new Web3.providers.HttpProvider(
//       "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
//     ); // Replace with your Infura project ID or your own Ethereum node URL

//     const contractABI = [
//       {
//         constant: true,
//         inputs: [{ name: "surveyId", type: "uint256" }],
//         name: "getSurvey",
//         outputs: [
//           { name: "question", type: "string" },
//           { name: "options", type: "string[]" },
//         ],
//         payable: false,
//         stateMutability: "view",
//         type: "function",
//       },
//     ];

//     const contract = new Web3.eth.Contract(contractABI, contractAddress);

//     async function fetchSurvey() {
//       const [question, options] = await contract.methods
//         .getSurvey(surveyId)
//         .call();
//       setSurvey({
//         id: surveyId,
//         question: question,
//         options: options,
//       });
//     }

//     fetchSurvey();
//   }, [surveyId, contractAddress]);

//   if (!survey) {
//     return <div>Loading survey...</div>;
//   }

//   return (
//     <div>
//       <h2>{survey.question}</h2>
//       <ul>
//         {survey.options.map((option) => (
//           <li key={option}>{option}</li>
//         ))}
//       </ul>
//     </div>
//   );
// };

// export default SurveyComponent;
