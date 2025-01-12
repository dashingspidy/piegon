# frozen_string_literal: true

class AlertComponent < ViewComponent::Base
  def initialize(type:, message:)
    @type = type
    @message = message
  end

  def alert_color
    case @type
    when :alert
      "text-red-600"
    when :notice
      "text-green-600"
    else
      "text-black-600"
    end
  end
end
