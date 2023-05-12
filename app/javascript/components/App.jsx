import React from 'react'
import Header from './Header'
import Main from './Main'

function App() {
  return (
    <>
      <Header />
      <Main />
      <footer>
        <p className="credits">
          Project by <a href="https://twitter.com/davefaliskie" target="_blank">Dave Faliskie</a> • <a href="https://github.com/davefaliskie/siddhartha" target="_blank">Fork on GitHub</a>
        </p>
      </footer>
    </>
  )
}

export default App