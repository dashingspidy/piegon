import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "name", "error" ]

  connect() {
    const path = window.location.pathname
    const isEdit = path.includes('/edit')
    
    if (isEdit) {
      const templateId = path.split('/')[2]
      this.loadTemplateAndInitialize(templateId)
    } else {
      this.initializeStripoEditor()
    }
  }

  initializeStripoEditor() {
    this.getToken().then(token => {
      this.fetchEmptyTemplate().then(template => {
        this.initPlugin(template, token)
      }).catch(error => {
        this.showError("Failed to load template")
      })
    }).catch(error => {
      this.showError("Failed to authenticate with Stripo")
    })
  }

  async fetchEmptyTemplate() {
    const htmlPromise = fetch('https://raw.githubusercontent.com/ardas/stripo-plugin/master/Public-Templates/Basic-Templates/Empty-Template/Empty-Template.html')
      .then(response => response.text())
      
    const cssPromise = fetch('https://raw.githubusercontent.com/ardas/stripo-plugin/master/Public-Templates/Basic-Templates/Empty-Template/Empty-Template.css')
      .then(response => response.text())
      
    const [html, css] = await Promise.all([htmlPromise, cssPromise])
    return { html, css }
  }

  async getToken() {
    const response = await fetch('/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    
    const data = await response.json()
    if (data.error) {
      throw new Error(data.error)
    }
    return data.token
  }

  initPlugin(template, initialToken) {
    const container = document.querySelector('#stripoEditorContainer')
    if (container) {
      container.innerHTML = ''
    }
    
    window.UIEditor.initEditor(
      container,
      {
        html: template.html,
        css: template.css,
        metadata: {
          emailId: 'email_' + Date.now(),
          userId: '1',
          username: 'User'
        },
        locale: 'en',
        onTokenRefreshRequest: (callback) => {
          this.getToken().then(token => {
            callback(token)
          }).catch(error => {
            this.showError("Failed to refresh authentication token")
          })
        },
        codeEditorButtonSelector: '#codeEditor',
        undoButtonSelector: '#undoButton',
        redoButtonSelector: '#redoButton',
        mobileViewButtonSelector: '#mobileViewButton',
        desktopViewButtonSelector: '#desktopViewButton'
      }
    )
  }

  async loadTemplateAndInitialize(templateId) {
    try {      
      const response = await fetch(`/email_templates/${templateId}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error: ${response.status}`)
      }
      
      const data = await response.json()
      console.log("Template data received:", data)
      
      if (data.html && data.css) {
        console.log("HTML and CSS found, initializing editor with template")
        
        this.getToken().then(token => {
          this.initPlugin({ html: data.html, css: data.css }, token)
          
          if (this.hasNameTarget) {
            this.nameTarget.value = data.name
          }
        }).catch(error => {
          this.showError("Failed to authenticate with Stripo")
        })
      } else {
        this.showError("Template data is incomplete")
      }
    } catch (error) {
      this.showError("Failed to load template")
    }
  }

  saveHtml() {
    this.clearError()
    
    if (!this.nameTarget.value.trim()) {
      this.showError("Template name is required")
      return
    }

    if (!window.StripoEditorApi) {
      this.showError("Editor not fully initialized yet")
      return
    }

    try {
      window.StripoEditorApi.actionsApi.save((error) => {
        if (error) {
          this.showError("Failed to save changes")
          return
        }
        
        window.StripoEditorApi.actionsApi.compileEmail({
          callback: (error, compiledHtml) => {
            if (error) {
              this.showError("Failed to compile email")
              return
            }
            
            window.StripoEditorApi.actionsApi.getTemplateData((templateData) => {
              if (templateData && templateData.html && templateData.css) {
                this.saveTemplateToServer(compiledHtml, templateData)
              } else {
                this.showError("Could not get template content")
              }
            })
          }
        })
      })
    } catch (error) {
      this.showError("Failed to save template")
    }
  }

  saveTemplateToServer(compiledHtml, templateData) {
    const EmailBody = new FormData()
    EmailBody.append("email_template[name]", this.nameTarget.value)
    EmailBody.append("email_template[editor]", "draganddrop")
    EmailBody.append("email_template[body]", compiledHtml)
    EmailBody.append("email_template[html]", templateData.html)
    EmailBody.append("email_template[css]", templateData.css)

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
      this.showError("Failed to save template")
    })
  }

  showError(message) {
    this.errorTarget.textContent = message
  }

  clearError() {
    this.errorTarget.textContent = ""
  }
}