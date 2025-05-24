Rails.application.routes.draw do
  resources :tickets, except: [ :edit, :update, :destroy ] do
    post "reply", to: "tickets#reply"
  end
  get "tracking/open"
  mount MissionControl::Jobs::Engine, at: "/jobs"
  root "home#index"
  get "privacy-policy", to: "home#privacy"
  get "term-and-conditions", to: "home#terms"
  get "help", to: "home#help"
  get "dashboard", to: "dashboard#index"
  get "unsubscribe", to: "unsubscribe#unsubscribe", as: :unsubscribe
  get "confirm_registration", to: "registrations#confirm"
  post "resend_confirmation_email", to: "registrations#resend_confirmation"
  get "procced_to_payment", to: "registrations#procced_to_payment"
  get "customer_portal", to: "accounts#customer_portal"
  get "up" => "rails/health#show", as: :rails_health_check
  post "embed/:api_token", to: "subscribers#embed"
  post "webhook", to: "accounts#webhook"
  get "tracking/open", to: "tracking#open", as: :tracking_pixel
  post "token", to: "email_templates#token"

  resource :registration, only: [ :new, :create ]
  resource :session

  get "/auth/:provider/callback", to: "oauth#google"
  get "/auth/failure", to: "oauth#failure"
  resources :passwords, param: :token
  resources :accounts, only: [ :destroy ] do
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
  resources :campaigns
end
