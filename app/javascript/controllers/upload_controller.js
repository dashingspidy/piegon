import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file"]

  submit(event) {
    if (!this.fileTarget.files[0]) {
      event.preventDefault()
      alert("Please select a file to upload")
      return
    }
  }
}