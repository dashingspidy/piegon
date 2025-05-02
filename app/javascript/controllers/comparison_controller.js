import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["provider", "price10k", "price50k", "price100k", "total"]

  providers = {
    mailchimp: {
      prices: { "10k": 199, "50k": 499, "100k": 999 },
      total: 59940
    },
    sendgrid: {
      prices: { "10k": 150, "50k": 400, "100k": 850 },
      total: 51000
    },
    convertkit: {
      prices: { "10k": 119, "50k": 379, "100k": 679 },
      total: 40800
    }
  }

  connect() {
    this.selectProvider("mailchimp")
  }

  selectProvider(provider) {
    const data = this.providers[provider]
    this.price10kTarget.textContent = `$${data.prices["10k"]}`
    this.price50kTarget.textContent = `$${data.prices["50k"]}`
    this.price100kTarget.textContent = `$${data.prices["100k"]}`
    this.totalTarget.textContent = `$${data.total.toLocaleString()}`
  }

  change(event) {
    this.selectProvider(event.target.value)
  }
}