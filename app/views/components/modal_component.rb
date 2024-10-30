# frozen_string_literal: true

class ModalComponent < ViewComponent::Base

  def initialize(name:, header:)
    @name = name
    @header = header
  end
end
