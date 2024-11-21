Rails.application.routes.draw do
  if Rails.env.production?
    get "/", to: "home#beta"
    get "up" => "rails/health#show", as: :rails_health_check
  end

  if Rails.env.development?
    root "home#index"
    get "dashboard", to: "dashboard#index"
    resource :registration, only: [ :new, :create ]
    resource :session
    resources :passwords, param: :token
    get "confirm_registration", to: "registrations#confirm"
    get "up" => "rails/health#show", as: :rails_health_check
    post "embed/:api_token", to: "subscribers#embed"

    resources :campaigns do
      resources :subscribers do
        collection do
          post :upload
          post :parse_csv
        end
      end
    end
    resources :email_templates, only: [ :index, :create, :new ] do
      collection do
        get :draganddrop
      end
    end
  end
end
