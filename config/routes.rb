Rails.application.routes.draw do
  root "pages#index"

  namespace :api do
    namespace :v1 do
      post 'questions/ask'
    end
  end
end
