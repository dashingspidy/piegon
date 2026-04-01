Rails.application.routes.draw do
  resources :tickets, except: [ :edit, :update, :destroy ] do
    post "reply", to: "tickets#reply"
  end
  mount MissionControl::Jobs::Engine, at: "/jobs"
  root "home#index"
  get "privacy-policy", to: "home#privacy"
  get "term-and-conditions", to: "home#terms"
  get "help", to: "home#help"
  get "dashboard", to: "dashboard#index"
  get "unsubscribe", to: "unsubscribe#unsubscribe", as: :unsubscribe
  get "confirm_registration", to: "registrations#confirm"
  post "resend_confirmation_email", to: "registrations#resend_confirmation"
  get "up" => "rails/health#show", as: :rails_health_check
  post "embed/:api_token", to: "subscribers#embed"
  post "sendgrid/webhook", to: "sendgrid_webhooks#webhook"

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

  resources :campaigns
  resources :domain_verifications do
    member do
      post :verify
      post :check_status
    end
  end

  resources :articles, only: [ :index, :show ]
end
