import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-editor"
export default class extends Controller {
  static targets = [ "name", "error" ]

  connect() {
    unlayer.init({
      id: 'editor',
      projectId: 252280,
      displayMode: 'email'
    })
  }

  saveHtml() {
    this.clearError()

    if (!this.nameTarget.value.trim()) {
      this.showError("Template name is required")
      return
    }

    unlayer.exportHtml((data) => {
      const EmailBody = new FormData()
      EmailBody.append("email_template[name]", this.nameTarget.value)
      EmailBody.append("email_template[editor]", "draganddrop")
      EmailBody.append("email_template[body]", data.html)
      EmailBody.append("email_template[template]", JSON.stringify(data.design))
      
      fetch("/email_templates", {
        method: "POST",
        headers: {
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: EmailBody
      })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          this.showError(data.error)
        } else {
          window.location.href = "/email_templates"
        }
      })
      .catch(error => {
        this.showError(error)
      })
    })
  }

  showError(message) {
    this.errorTarget.textContent = message
  }

  clearError() {
    this.errorTarget.textContent = ""
  }
}
