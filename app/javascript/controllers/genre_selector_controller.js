import { Controller } from "@hotwired/stimulus"

// Controls the two-step genre selection:
// 1. Click a parent genre to expand it
// 2. Select sub-genres from the expanded section
export default class extends Controller {
  static targets = ["parentSection"]

  connect() {
    // Auto-expand sections that have selected children
    this.parentSectionTargets.forEach(section => {
      if (this.hasSelectedChildren(section)) {
        section.classList.add("expanded")
      }
    })
  }

  toggle(event) {
    const section = event.currentTarget.closest("[data-genre-selector-target='parentSection']")
    section.classList.toggle("expanded")
  }

  hasSelectedChildren(section) {
    const checkboxes = section.querySelectorAll("input[type='checkbox']:checked")
    return checkboxes.length > 0
  }
}
