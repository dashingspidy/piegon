import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Ensure the modal is properly initialized
    document.addEventListener('turbo:before-render', this.cleanup.bind(this))
  }
  
  disconnect() {
    this.cleanup()
  }
  
  cleanup() {
    // Clean up any background or overlay elements that might be stuck
    const overlays = document.querySelectorAll('.modal-backdrop, .bg-gray-900, .opacity-50, .fixed')
    overlays.forEach(el => {
      if (el.classList.contains('modal-backdrop') || 
          (el.classList.contains('fixed') && 
           el.classList.contains('opacity-50') && 
           !el.id)) {
        el.remove()
      }
    })
    
    // Restore scrolling to the body if it was disabled
    document.body.classList.remove('overflow-hidden')
  }
  
  close() {
    // Find the closest modal element
    const modalElement = this.element.querySelector('[id]') || 
                         this.element.closest('[id]')
    
    const modalId = modalElement ? modalElement.id : null
    
    if (modalId) {
      const modal = document.getElementById(modalId)
      
      // If using Flowbite (based on the HTML structure)
      if (window.Modal) {
        const modalInstance = window.Modal.getOrCreateInstance(modal)
        modalInstance.hide()
      } else {
        // Fallback to manually hiding the modal
        modal.classList.add('hidden')
        this.cleanup()
      }
    }
  }
}