class AuthController < ApplicationController
  AUTHORIZATION_URI  = "https://login.uber.com/oauth/v2/authorize?client_id=#{Rails.application.secrets.uber['client_id']}&response_type=code"
  AUTHORIZATION_CODE = 'SECRET_AUTHORIZATION_CODE'

  def authorize
    session[:redirect_uri]    = params[:redirect_uri]
    session[:messenger_id]    = params[:messenger_id]
    session[:previous_method] = params[:previous_method]
    redirect_to AUTHORIZATION_URI
  end

  def authorize_response
    if Auth.new(session[:messenger_id]).login(params[:code])
      redirect_to(session[:redirect_uri] + "&authorization_code=#{AUTHORIZATION_CODE}[#{session[:previous_method]}]")
    else
      redirect_to(session[:redirect_uri])
    end
  end
end
