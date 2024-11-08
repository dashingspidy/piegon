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

  saveHtml() {
    unlayer.exportHtml((data) => {
      const html = data.html
      console.log(html)
    })
  }

  saveJson() {
    unlayer.exportHtml((data) => {
      const design = data.design
      console.log(design)
    })
  }
}
