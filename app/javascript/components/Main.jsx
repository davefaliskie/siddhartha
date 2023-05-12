import React from 'react'
import QuestionForm from './QuestionForm'

function Main() {
  // const { answer, audioSrcUrl } = props;

  return (
    <div className="main">
      <p className="credits">This is an experiment in using AI to make the content from the book Siddhartha by Hermann Hesse more accessible. Ask a question and AI'll answer it in real-time:</p>

      <QuestionForm />

    </div>
  )
}

export default Main