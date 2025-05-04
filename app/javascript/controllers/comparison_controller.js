import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["provider", "price10k", "price50k", "price100k", "total"]

  providers = {
    mailchimp: {
      prices: { "10k": 135, "50k": 450, "100k": 800 },
      total: 48000
    },
    mailerlite: {
      prices: { "10k": 73, "50k": 289, "100k": 440 },
      total: 26400
    },
    convertkit: {
      prices: { "10k": 119, "50k": 379, "100k": 679 },
      total: 40740
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