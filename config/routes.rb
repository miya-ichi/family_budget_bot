Rails.application.routes.draw do
  post 'callback', to: 'line_bot#callback'

  namespace :admin do
    get 'expenses', to: 'expenses#index'
  end
end
