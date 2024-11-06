import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-editor"
export default class extends Controller {
  connect() {
    unlayer.init({
      id: 'editor',
      projectId: 252280,
      displayMode: 'email'
    })
  }
}
