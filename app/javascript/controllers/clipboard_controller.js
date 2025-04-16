import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "labelDefault", "labelCopied"]

  copy() {
    navigator.clipboard.writeText(this.inputTarget.textContent).then(() => {
      this.labelDefaultTarget.classList.add("hidden")
      this.labelCopiedTarget.classList.remove("hidden")

      setTimeout(() => {
        this.labelCopiedTarget.classList.add("hidden")
        this.labelDefaultTarget.classList.remove("hidden")
      }, 1500)
    }).catch(() => {
      this.labelCopiedTarget.textContent = "Error"
    })
  }
}

