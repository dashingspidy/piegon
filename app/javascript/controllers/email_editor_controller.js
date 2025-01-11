import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "name", "error" ]

  connect() {
    unlayer.init({
      id: 'editor',
      projectId: 252280,
      displayMode: 'email'
    })

    const path = window.location.pathname
    if (path.includes('/edit')) {
      const templateId = path.split('/')[2]
      this.loadTemplate(templateId)
    }
  }

  async loadTemplate(templateId) {
    try {
      const response = await fetch(`/email_templates/${templateId}/edit`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      
      const data = await response.json()
      
      if (data.template) {
        const design = JSON.parse(data.template)
        unlayer.loadDesign(design)
        
        if (this.hasNameTarget) {
          this.nameTarget.value = data.name
        }
      }
    } catch (error) {
      this.showError("Failed to load template")
      console.error("Error loading template:", error)
    }
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

      const path = window.location.pathname
      const isEdit = path.includes('/edit')
      const templateId = isEdit ? path.split('/')[2] : null
      
      const url = isEdit ? `/email_templates/${templateId}` : "/email_templates"
      const method = isEdit ? "PATCH" : "POST"

      fetch(url, {
        method: method,
        headers: {
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        },
        body: EmailBody
      })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          this.showError(data.error)
        } else {
          window.location.href = data.redirect_url || "/email_templates"
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