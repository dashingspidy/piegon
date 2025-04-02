import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: String
  }

  connect() {
    // Listen for Turbo Stream replacements
    document.addEventListener('turbo:frame-render', this.resetModal.bind(this));
  }

  disconnect() {
    document.removeEventListener('turbo:frame-render', this.resetModal.bind(this));
  }

  resetModal(event) {
    // Only run on our target frame
    if (event.target.id !== "modal_form_content") return;
    
    // Force re-initialization of modal components
    setTimeout(() => {
      const modalId = this.idValue || "csvUploadModal";
      const modal = document.getElementById(modalId);
      
      // If you're using Flowbite
      if (window.Modal && modal) {
        // Get the overlay element
        const overlay = document.querySelector('.bg-gray-900.bg-opacity-50.fixed.inset-0.z-40');
        
        // If there are duplicate overlays, remove all but one
        const overlays = document.querySelectorAll('.bg-gray-900.bg-opacity-50.fixed.inset-0.z-40');
        if (overlays.length > 1) {
          for (let i = 1; i < overlays.length; i++) {
            overlays[i].remove();
          }
        }
        
        // Re-initialize modal
        const modalInstance = window.Modal.getOrCreateInstance(modal);
        
        // Ensure close buttons work
        const closeButtons = modal.querySelectorAll('[data-modal-hide]');
        closeButtons.forEach(button => {
          button.addEventListener('click', () => {
            modalInstance.hide();
          });
        });
      }
    }, 50);
  }
}