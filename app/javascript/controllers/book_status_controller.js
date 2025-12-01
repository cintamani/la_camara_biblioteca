import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["borrowerField"]

  toggle(event) {
    const status = event.target.value
    const borrowerField = document.querySelector("[data-book-status-target='borrowerField']")

    if (status === "out") {
      borrowerField.style.display = ""
    } else {
      borrowerField.style.display = "none"
    }
  }
}
