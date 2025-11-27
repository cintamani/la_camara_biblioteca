import { Controller } from "@hotwired/stimulus"

// Controls the two-step genre selection:
// 1. Click a parent genre to expand it
// 2. Select sub-genres from the expanded section
// 3. Search to filter and auto-expand matching genres
export default class extends Controller {
  static targets = ["parentSection", "searchInput", "option"]

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

  // Normalize text: lowercase and remove accents
  normalize(text) {
    return text.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
  }

  search() {
    const query = this.normalize(this.searchInputTarget.value.trim())

    this.parentSectionTargets.forEach(section => {
      const options = section.querySelectorAll("[data-genre-selector-target='option']")
      const parentName = this.normalize(section.querySelector(".genre-section-title").textContent)
      let hasMatch = false

      if (query === "") {
        // No search - show all, collapse unless has selected children
        options.forEach(opt => opt.classList.remove("hidden"))
        if (!this.hasSelectedChildren(section)) {
          section.classList.remove("expanded")
        }
        section.classList.remove("hidden")
      } else {
        // Filter options
        options.forEach(opt => {
          const name = this.normalize(opt.textContent)
          if (name.includes(query)) {
            opt.classList.remove("hidden")
            hasMatch = true
          } else {
            opt.classList.add("hidden")
          }
        })

        // Also match parent name
        if (parentName.includes(query)) {
          hasMatch = true
          options.forEach(opt => opt.classList.remove("hidden"))
        }

        if (hasMatch) {
          section.classList.remove("hidden")
          section.classList.add("expanded")
        } else {
          section.classList.add("hidden")
        }
      }
    })
  }

  clearSearch() {
    this.searchInputTarget.value = ""
    this.search()
  }

  hasSelectedChildren(section) {
    const checkboxes = section.querySelectorAll("input[type='checkbox']:checked")
    return checkboxes.length > 0
  }
}
