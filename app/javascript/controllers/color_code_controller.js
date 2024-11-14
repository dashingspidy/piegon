import { Controller } from "@hotwired/stimulus"
import HighlightedCode from "highlighted-code"

// Connects to data-controller="color-code"
export default class extends Controller {
  connect() {
    HighlightedCode.useTheme("github-dark")
  }
}
