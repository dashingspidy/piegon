# frozen_string_literal: true

class ClipboardComponent < ViewComponent::Base
  def initialize(header:)
    @header = header
  end
end
