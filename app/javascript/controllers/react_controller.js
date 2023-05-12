import { Controller } from "@hotwired/stimulus"
import React from "react"
import { createRoot } from "react-dom/client"
import App from "../components/App"

export default class extends Controller {
  connect() {
    console.log("🎉 Connected to react stimulus controller");
    const app = document.getElementById("app");
    createRoot(app).render(<App />);
  }
}
