import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const selects = this.element.querySelectorAll("select")
    const hasMapping = Array.from(selects).some(select => select.value !== "")
    
    if (!hasMapping) {
      event.preventDefault()
      alert("Please map at least one column")
      return
    }
  }
}