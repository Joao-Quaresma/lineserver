Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  resources :file_uploads, only: [ :create, :index, :destroy ] do
    member do
      get "line/:line", action: :show
    end
  end
end
