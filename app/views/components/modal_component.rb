# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  def initialize(modalId:, name:, header:)
    @modalId = modalId
    @name = name
    @header = header
  end
end
