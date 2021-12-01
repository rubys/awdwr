import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="payment"
export default class extends Controller {
// START_HIGHLIGHT
  static targets = [ "selection", "additionalFields" ]

  initialize() {
    this.showAdditionalFields()
  }

  showAdditionalFields() {
    let selection = this.selectionTarget.value

    for (let target of this.additionalFieldsTargets) {
      target.disabled = target.hidden = (target.dataset.value != selection)
    }
  }
// END_HIGHLIGHT
}
