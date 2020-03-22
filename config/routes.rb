Rails.application.routes.draw do
  devise_for :admins
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  get '/',                    to: 'webhook#verifier'
  post '/',                   to: 'webhook#receiver'
  get '/authorize',           to: 'auth#authorize'
  get '/authorize_response',  to: 'auth#authorize_response'
  post '/uber_status_change', to: 'webhook#uber_status_change_receiver'
  get '/uber_surge_confirmation',  to: 'webhook#uber_surge_confirmation'
end
