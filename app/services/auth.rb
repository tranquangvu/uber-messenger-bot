class Auth
  attr_accessor :messenger_id

  REDIRECT_URI = "#{Rails.application.secrets.domain_url}/authorize_response"
  LOGIN_URI    = 'https://login.uber.com/oauth/v2/token'
  LOGOUT_URI   = 'https://login.uber.com/oauth/revoke'
  REFRESH_URI  = 'https://login.uber.com/oauth/v2/token'

  def initialize(messenger_id)
    @messenger_id = messenger_id
  end

  def login?
    return false unless !user.nil? && user.login?
    refresh_token if user.token_expired?
    true
  end

  def login(authorization_code)
    response = HTTParty.post(LOGIN_URI, {
      body: {
        client_secret: Rails.application.secrets.uber['client_secret'],
        client_id: Rails.application.secrets.uber['client_id'],
        redirect_uri: REDIRECT_URI,
        grant_type: 'authorization_code',
        code: authorization_code
      }
    })

    if response['error']
      Rails.logger.error "[ERROR]: #{response['error']}"
      return false
    else
      info = Api.new(response['access_token']).me
      logout_others(info['uuid'])
      user.update(
        access_token: response['access_token'],
        expires_in: response['expires_in'],
        refresh_token: response['refresh_token'],
        token_created_at: Time.current,
        first_name: info['first_name'],
        last_name: info['last_name'],
        email: info['email'],
        promo_code: info['promo_code'],
        uuid: info['uuid']
      )
      return true
    end
  end

  def logout
    response = HTTParty.post(LOGOUT_URI, {
      body: {
        client_secret: Rails.application.secrets.uber['client_secret'],
        client_id: Rails.application.secrets.uber['client_id'],
        token: user.access_token
      }
    })
    response['error'] ? Rails.logger.error("[ERROR]: #{response['error']}") : 
      user.update(access_token: nil, expires_in: nil, refresh_token: nil, token_created_at: nil)
  end

  private

  def user
    @user ||= User.find_by(messenger_id: messenger_id)
  end

  def logout_others(uuid)
    others = User.where('uuid = ? AND messenger_id != ?', uuid, messenger_id)
    others.update(
      access_token: nil, 
      expires_in: nil, 
      refresh_token: nil, 
      token_created_at: nil,
      first_name: nil,
      last_name: nil,
      email: nil,
      promo_code: nil,
      uuid: nil
    )
  end

  def refresh_token
    response = HTTParty.post(REFRESH_URI, {
      body: {
        client_secret: Rails.application.secrets.uber['client_secret'],
        client_id: Rails.application.secrets.uber['client_id'],
        redirect_uri: REDIRECT_URI,
        grant_type: 'refresh_token',
        refresh_token: user.refresh_token
      }
    })

    if response['error']
      Rails.logger.error "[ERROR]: #{response['error']}"
    else
      user.update(
        access_token: response['access_token'],
        expires_in: response['expires_in'],
        refresh_token: response['refresh_token'],
        token_created_at: Time.current
      )
    end
  end
end
