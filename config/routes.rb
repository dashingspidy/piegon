Rails.application.routes.draw do
  root "home#index"
  get "privacy-policy", to: "home#privacy"
  get "term-and-conditions", to: "home#terms"
  get "help", to: "home#help"
  get "dashboard", to: "dashboard#index"
  get "unsubscribe", to: "unsubscribe#unsubscribe", as: :unsubscribe
  get "confirm_registration", to: "registrations#confirm"
  get "up" => "rails/health#show", as: :rails_health_check
  post "embed/:api_token", to: "subscribers#embed"
  resource :registration, only: [ :new, :create ]
  resource :session
  resources :passwords, param: :token
  resources :accounts do
    collection do
      get :profile
      get :billing
      patch :update_password
    end
  end
  resources :contacts do
    resources :subscribers do
      collection do
        post :upload
        post :parse_csv
      end
    end
  end
  resources :email_templates do
    collection do
      get :draganddrop
    end
  end
  resources :mail_settings
end
