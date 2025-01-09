import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pricing"
export default class extends Controller {
  static targets = ["planSelect", "price", "planLink" ]
  
  connect() {
    this.updatePrice()
  }

  updatePrice() {
    const selectedOption = this.planSelectTarget.selectedOptions[0]
    const price = selectedOption.dataset.price
    const planValue = selectedOption.value
    this.priceTarget.textContent = price
    const currentPath = this.planLinkTarget.href
    const baseUrl = currentPath.split('?')[0]
    this.planLinkTarget.href = `${baseUrl}?plan=${planValue}`
  }
}
