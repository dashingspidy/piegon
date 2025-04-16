module ApplicationHelper
  include Pagy::Frontend
  def active_link(url_path)
    "active" if request.path.start_with?(url_path)
  end

  def number_to_k(number)
    number_to_human(number, format: "%n%u", units: { thousand: "K" })
  end

  def free_account
    Current.user.plan == "free"
  end

  def pagy_nav(pagy)
    html = %(<div class="join" aria-label="Pages">)

    if pagy.prev
      html << %(<a href="#{pagy_url_for(pagy, pagy.prev)}" class="join-item btn" aria-label="Previous">«</a>)
    else
      html << %(<button class="join-item btn" aria-disabled="true" aria-label="Previous">«</button>)
    end

    pagy.series.each do |item|
      if item.is_a? Integer
        html << %(<a href="#{pagy_url_for(pagy, item)}" class="join-item btn">#{item}</a>)
      elsif item.is_a? String
        html << %(<button class="join-item btn btn-active" aria-disabled="true" aria-current="page">#{item}</button>)
      elsif item == :gap
        html << %(<button class="join-item btn btn-disabled" aria-disabled="true">...</button>)
      end
    end

    if pagy.next
      html << %(<a href="#{pagy_url_for(pagy, pagy.next)}" class="join-item btn" aria-label="Next">»</a>)
    else
      html << %(<button class="join-item btn" aria-disabled="true" aria-label="Next">»</button>)
    end

    html << %(</div>)

    html.html_safe
  end
end
