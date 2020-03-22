RailsAdmin.config do |config|
  # authenticate with devise
  config.authenticate_with do
    warden.authenticate! scope: :admin
  end
  config.current_user_method(&:current_admin)

  # app name
  config.main_app_name = 'Uber Bot'

  # actions
  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end
end
