import React from 'react'

function QuestionForm() {
  return (
    <form action="#" method="post">
      <textarea name="question" id="question"></textarea>

      <div className="buttons">
        <button type="submit" id="ask-button">Ask question</button>
      </div>
    </form>
  )
}

export default QuestionForm