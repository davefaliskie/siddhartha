import React, { useState }  from 'react'

function QuestionForm() {
  // Set default question here, it'll hit the api cache for the answer.
  const [query, setQuery] = useState('What is this book about?');
  const [answer, setAnswer] = useState('');
  const [showAskButton, setShowAskButton] = useState(true);

  const handleChange = (event) => {
    setQuery(event.target.value);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    
    const askButton = document.getElementById("ask-button");

    askButton.textContent = "Asking...";
    askButton.disabled = true;

    fetch('/api/v1/questions/ask', {
      method: 'POST',
      body: JSON.stringify({ query }),
      headers: {
        'Content-Type': 'application/json',
      },
    })
      .then((response) => {
        if (response.status === 200) {
          response.json().then((data) => {
            setAnswer(data.answer);
            setShowAskButton(false);
            askButton.textContent = "Ask question";
            askButton.disabled = false;
          });
        } else {
          console.log('Error:', response.status);
        }
      })
      .catch((error) => {
        console.log('Error:', error);
      });
  };

  const handleReset = (event) => {
    event.preventDefault();

    setQuery('');
    setAnswer('');
    setShowAskButton(true);
    document.getElementById('question').focus();
  };


  return (
    <form onSubmit={handleSubmit}>
      <textarea 
        name="question" 
        id="question"
        value={query}
        onChange={handleChange}
        placeholder="Enter your question"
      ></textarea>

      {showAskButton ? (
        <div className="buttons">
          <button type="submit" id="ask-button">Ask question</button>
        </div>
      ) : null }

      {answer != "" ? (
        <>
          <p id="answer-container">
            <strong>Answer:</strong> <span id="answer">{ answer }</span> 
          </p>
          <button onClick={handleReset} id="ask-another-button">Ask another question</button>
        </>
      ) : null}
      
    </form>
  )
}

export default QuestionForm