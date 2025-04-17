import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scheduleField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selected = this.element.querySelector("input[name='campaign[send_time_option]']:checked")
    const showSchedule = selected?.value === "later"
    this.scheduleFieldTarget.hidden = !showSchedule
  }
}
