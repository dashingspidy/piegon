Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  resource :registration, only: [ :new, :create ]
  resource :session
  resources :passwords, param: :token
  get "confirm_registration", to: "registrations#confirm"
  get "up" => "rails/health#show", as: :rails_health_check
  post "embed/:api_token", to: "subscribers#embed"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
  resources :campaigns do
    resources :subscribers do
      collection do
        post :upload
        post :parse_csv
      end
    end
  end
end
