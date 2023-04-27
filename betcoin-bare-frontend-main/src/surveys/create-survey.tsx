import React, { useState } from 'react';

type Answer = {
  id: number,
  text: string
}

type SurveyProps = {
  onSubmit: (question: string, answers: Answer[]) => void
}

const SurveyQuestionForm: React.FC<SurveyProps> = ({ onSubmit }) => {
  const [question, setQuestion] = useState<string>('');
  const [answers, setAnswers] = useState<Answer[]>([{id: 0, text: ''}]);

  const handleQuestionChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setQuestion(event.target.value);
  }

  const handleAnswerChange = (event: React.ChangeEvent<HTMLInputElement>, id: number) => {
    const updatedAnswers = answers.map((answer) => {
      if (answer.id === id) {
        return {
          ...answer,
          text: event.target.value
        };
      }
      return answer;
    });
    setAnswers(updatedAnswers);
  }

  const handleAddAnswer = () => {
    const newId = answers.length;
    const newAnswer = {id: newId, text: ''};
    setAnswers([...answers, newAnswer]);
  }

  const handleRemoveAnswer = (id: number) => {
    const updatedAnswers = answers.filter((answer) => answer.id !== id);
    setAnswers(updatedAnswers);
  }

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onSubmit(question, answers);
  }

  return (
    <div className="flex max-w-xs flex-col gap-4 rounded-xl bg-white/10 p-4 text-white hover:bg-white/20">
      <p className='text-2xl'>Create Poll</p>
      <form onSubmit={handleSubmit}>
        <label htmlFor="question">Question:</label>
        <br/>
        <input className="text-black" type="text" id="question" value={question} onChange={handleQuestionChange} />
        <br/>
        <label>Answers:</label>
        {answers.map((answer) => (
          <div key={answer.id}>
            <input  className="text-black" type="text" value={answer.text} onChange={(event) => handleAnswerChange(event, answer.id)} />
            <button type="button" onClick={() => handleRemoveAnswer(answer.id)}> Remove</button>
          </div>
        ))}
        <br/>
        <button type="button" onClick={handleAddAnswer}>Add Answer</button>
        <br/>
        <button type="submit">Submit</button>
      </form>
    </div>
  );
}

export default SurveyQuestionForm;
