import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="email-editor"
export default class extends Controller {
  static targets = [ "name" ]

  connect() {
    unlayer.init({
      id: 'editor',
      projectId: 252280,
      displayMode: 'email'
    })
  }

  saveHtml() {
    unlayer.exportHtml((data) => {
      const html = data.html
      const EmailBody = new FormData()
      EmailBody.append("email_templates[name]", this.nameTarget.value)
      EmailBody.append("email_templates[body]", html)
      fetch("/email_templates", {
        method: "POST",
        headers: {
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: EmailBody
      })
    })
  }

  saveJson() {
    unlayer.exportHtml((data) => {
      const template = data.design
      const EmailBody = new FormData()
      EmailBody.append("email_templates[name]", this.nameTarget.value)
      EmailBody.append("email_templates[template]", JSON.rawJSON(template))
      fetch("/email_templates", {
        method: "POST",
        headers: {
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: EmailBody
      })
    })
  }
}
