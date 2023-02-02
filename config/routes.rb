Rails.application.routes.draw do
  post 'callback', to: 'line_bot#callback'

  namespace :admin do
    resources :expenses
  end
end
