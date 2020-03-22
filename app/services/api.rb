class Api
  include HTTParty
  base_uri Rails.env == 'production' ? 'https://api.uber.com' : 'https://sandbox-api.uber.com'

  attr_accessor :access_token

  def initialize(access_token)
    @access_token = access_token
  end

  def products(params = {})
    self.class.get("/v1/products", {
      headers: { 'Authorization': "Bearer #{access_token}" },
      query: params
    })['products']
  end

  def product_name_by_id(product_id)
    self.class.get("/v1/products/#{product_id}", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })['display_name']
  end

  def estimate_price(params = {})
    self.class.get("/v1/estimates/price", {
      headers: { 'Authorization': "Bearer #{access_token}" },
      query: params
    })
  end

  def estimate_price_by_product(product_id, params = {})
    response = estimate_price(params)
    response['prices'].find{|price| price['product_id'] == product_id}
  end

  def history
    self.class.get("/v1.2/history", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })['history']
  end

  def me
    self.class.get("/v1/me", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })
  end

  def request(params = {})
    self.class.post('/v1/requests', {
      headers: {
        'Content-type': 'application/json',
        'Authorization': "Bearer #{access_token}"
      },
      body: params.to_json
    })
  end

  def request_current
    self.class.get("/v1/requests/current", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })
  end

  def delete_request_current
    self.class.delete("/v1/requests/current", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })
  end

  def map(request_id)
    self.class.get("/v1/requests/#{request_id}/map", {
      headers: { 'Authorization': "Bearer #{access_token}" } 
    })
  end

  def receipt(request_id)
    self.class.get("/v1/requests/#{request_id}/receipt", { 
      headers: { 'Authorization': "Bearer #{access_token}" } 
    })
  end

  def payment_methods
    self.class.get("/v1/payment-methods", {
      headers: { 'Authorization': "Bearer #{access_token}" }
    })['payment_methods']
  end


  # Sanbox test only
  
  def sandbox_update_request(request_id, params = {})
    self.class.put("/v1/sandbox/requests/#{request_id}", {
      headers: {
        'Content-type': 'application/json',
        'Authorization': "Bearer #{access_token}"
      },
      body: params.to_json
    })
  end

  def sanbox_update_product(product_id, params = {})
    self.class.put("/v1/sandbox/products/#{product_id}", {
      headers: {
        'Content-type': 'application/json',
        'Authorization': "Bearer #{access_token}"
      },
      body: params.to_json
    })
  end
end
