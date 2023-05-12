import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("🎉 Connected to react stimulus controller");
  }
}
