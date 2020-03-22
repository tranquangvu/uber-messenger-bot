class Bot
  attr_accessor :entry, :sender_id

  VALID_MESSAGE_TYPE     = ['text', 'quick_reply', 'attachments']
  VALID_MESSAGING_EVENTS = ['optin', 'message', 'delivery', 'postback', 'account_linking', 'surge_confirmation']
  ANWSER_PAYLOADS        = ['CONFIRM_RIDE', 'CANCEL_RIDE', 'DISPLAY_BOOKMARK_TO_SELECT', 'SELECT_PRODUCT', 'SELECT_PAYMENT_METHOD', 'SELECT_BOOKMARK']

  def initialize(entry)
    @entry     = entry
    @sender_id = entry.first[:messaging].first[:sender][:id]
  end

  def reply
    entry.each do |page_entry|
      page_entry[:messaging].each do |messaging_event|
        begin
          send("received_#{(messaging_event.stringify_keys.keys & VALID_MESSAGING_EVENTS).join}", messaging_event)
        rescue Exception => e
          Rails.logger.error "[ERROR]: Webhook received unknown messaging envent: #{e}"
        end
      end
    end
  end

  private

  def api
    @api ||= Api.new(user.access_token)
  end

  def auth
    @auth ||= Auth.new(sender_id)
  end

  def user
    @user ||= User.find_by(messenger_id: sender_id)
  end

  def conversation
    @conversation ||= user.conversation
  end

  def current_ride
    @current_ride ||= user.current_ride
  end

  def current_bookmark
    @current_bookmark ||= user.current_bookmark
  end

  def current_question
    @current_question ||= conversation.current_question
  end

  def set_question(value)
    conversation.update(current_question: value)
  end

  def send_message(message)
    MessengerReplyJob.perform_now(Messenger::SendApi.message(recipient_id: sender_id, message: message))
  end

  def received_message(event)
    begin
      type = (event[:message].stringify_keys.keys & VALID_MESSAGE_TYPE).first
      send("#{type}_message_handler", event[:message][type])
    rescue Exception => e
      Rails.logger.error "[ERROR]: #{e}"  
    end
  end

  def quick_reply_message_handler(quick_reply)
    payload = quick_reply[:payload]

    begin
      destroy_undone_progress unless anwser_payload?(payload)
      send payload.downcase
    rescue Exception => e
      Rails.logger.error "[ERROR]: #{e}"
    end
  end

  def text_message_handler(text)
    if current_question
      message_anwser(current_question, text)
    else
      case text
      when 'hi', 'hello'
        start
      when 'logout'
        logout
      else
        send_message MessageTemplate.unknow
      end
    end
  end

  def attachments_message_handler(attachments)
    return unless current_question == 'location' || current_question == 'destination'
    attachments.each do |attachment|
      next unless attachment[:type] == 'location'
      message_anwser(current_question, attachment[:payload][:coordinates])
    end
  end

  def received_postback(event)
    payload         = event[:postback][:payload]
    payload_data    = payload[/\((.*?)\)/, 1]
    payload_method  = payload.gsub("(#{payload_data})", '')

    begin
      destroy_undone_progress unless payload == 'GET_STARTED' || anwser_payload?(payload_method)
      payload_data ? send(payload_method.downcase, payload_data) : send(payload_method.downcase)
    rescue Exception => e
      Rails.logger.error "[ERROR]: #{e}"
    end
  end

  def anwser_payload?(payload)
    return false unless current_question
    ANWSER_PAYLOADS.each{ |anwser_payload| return true if payload == anwser_payload }
    false
  end

  def destroy_undone_progress
    current_ride.destroy if current_ride
    current_bookmark.destroy if current_bookmark
    current_ride = current_bookmar = nil
  end

  def received_account_linking(event)
    status = event[:account_linking][:status]
    previous_method = event[:account_linking][:authorization_code][/\[(.*?)\]/, 1]
    status == 'linked' ? logged_in(previous_method) : logged_out
  end

  def logged_in(previous_method)
    send_message MessageTemplate.logged_in_successfully(previous_method)
  end

  def logged_out
    auth.logout
    send_message MessageTemplate.logged_out_successfully
  end

  def received_optin(event)
  end

  def received_delivery(event)
  end

  def received_surge_confirmation(event)
    request_ride(event[:surge_confirmation][:surge_confirmation_id])
  end

  def valid_address?(address)
    !Geocoder.coordinates(address).nil?
  end

  def message_anwser(question, anwser)
    begin
      send("message_anwser_#{question}", anwser) if question
    rescue Exception => e
      Rails.logger.error "[ERROR]: #{e}"
    end
  end

  def message_anwser_location(location)
    if location.is_a? String
      return send_message(MessageTemplate.request_location_again) unless valid_address?(location)
      user.rides.create(location: location)
    else
      user.rides.create(location_latitude: location[:lat], location_longitude: location[:long])
    end
    request_destination
  end

  def message_anwser_destination(destination)
    if destination.is_a? String
      return send_message(MessageTemplate.request_destination_again) unless valid_address?(destination)
      current_ride.update(destination: destination)
    else
      current_ride.update(destination_latitude: destination[:lat], destination_longitude: destination[:long]) 
    end
    request_product
  end

  def message_anwser_bookmark_name(name)
    user.bookmarks.create(name: name)
    request_bookmark_address
  end

  def message_anwser_bookmark_address(address)
    set_question nil
    if current_bookmark.update(address: address, active: false)
      send_message MessageTemplate.create_bookmark_successfully(current_bookmark)
    else
      send_message MessageTemplate.create_bookmark_unsuccessfully(current_bookmark)
    end
  end

  def message_anwser_feedback(content)
    set_question nil
    if user.feedbacks.create(content: content)
      send_message MessageTemplate.create_feedback_successfully
    else
      send_message MessageTemplate.create_feedback_unsuccessfully
    end
  end

  def login(previous_method)
    url = "#{Rails.application.secrets.domain_url}/authorize?messenger_id=#{sender_id}&previous_method=#{previous_method}"
    send_message MessageTemplate.login(url)
  end

  def logout
    send_message MessageTemplate.logout
  end

  def start
    send_message MessageTemplate.welcome
  end

  def get_started
    user = User.create(messenger_id: sender_id)
    user.create_conversation
    send_message MessageTemplate.welcome
  end

  def ride
    return login(__callee__) unless auth.login?
    set_question nil
    request_location
  end

  def request_location
    set_question 'location'
    send_message MessageTemplate.request_location_by_attachment
    send_message MessageTemplate.attachment_guide
    send_message MessageTemplate.request_location_by_text
  end

  def request_destination
    set_question 'destination'
    send_message MessageTemplate.request_destination_by_attachment
    send_message MessageTemplate.attachment_guide
    send_message MessageTemplate.request_destination_by_text
  end

  def display_bookmark_to_select
    send_message MessageTemplate.bookmark_list_to_select(user.bookmarks)
  end

  def select_bookmark(bookmark_address)
    return unless current_question == 'location' || current_question == 'destination'
    message_anwser(current_question, bookmark_address)
  end

  def request_product
    products = api.products(latitude: current_ride.location_latitude, longitude: current_ride.location_longitude)
    if products && products.any?
      set_question 'product'
      send_message MessageTemplate.request_product
      send_message MessageTemplate.product_list(products)
    else
      set_question nil
      send_message MessageTemplate.no_product
    end
  end

  def select_product(product)
    return unless current_question == 'product'
    product_name, product_id = product.split(',')
    current_ride.update(product: product_name, product_id: product_id)
    estimate_price({name: product_name, id: product_id})
  end

  def estimate_price(product)
    set_question 'confirm_ride'
    # SANBOX ONLY ====================================================================================
    api.sanbox_update_product(product[:id], {surge_multiplier: 1.2}) unless Rails.env == 'production'
    # ================================================================================================
    price = api.estimate_price_by_product(product[:id], {
      start_latitude: current_ride.location_latitude,
      start_longitude: current_ride.location_longitude,
      end_latitude: current_ride.destination_latitude,
      end_longitude: current_ride.destination_longitude,
    })
    send_message MessageTemplate.estimated_price(price, product[:name])
  end

  def confirm_ride
    return unless current_question == 'confirm_ride'
    request_payment_method
  end

  def request_payment_method
    set_question 'payment_method'
    payment_methods = api.payment_methods
    send_message MessageTemplate.request_payment_method
    send_message MessageTemplate.payment_method_list(payment_methods)
  end

  def select_payment_method(payment_method)
    return unless current_question == 'payment_method'
    type, id = payment_method.split(',')
    current_ride.update(payment_method_type: type, payment_method_id: id)
    request_ride
  end

  def request_ride(surge_confirmation_id = nil)
    # first send finding ride message
    send_message MessageTemplate.finding_ride unless surge_confirmation_id

    # send request to api
    params = {
      start_latitude: current_ride.location_latitude,
      start_longitude: current_ride.location_longitude,
      end_latitude: current_ride.destination_latitude,
      end_longitude: current_ride.destination_longitude,
      product_id: current_ride.product_id,
      payment_method_id: current_ride.payment_method_id
    }
    params[:surge_confirmation_id] = surge_confirmation_id if surge_confirmation_id
    request_current = api.request(params)

    # hanlde request result
    if request_current['errors']
      request_current['errors'].each do |error|
        case error['code']
        when 'surge'
          surge_confirmation = request_current['meta']['surge_confirmation']          
          current_ride.update(surge_confirmation_id: surge_confirmation['surge_confirmation_id'])
          send_message MessageTemplate.surge_confirmation(surge_confirmation)
        else
          Rails.logger.error "[ERROR]: #{error}"
        end
      end
    else
      # SANBOX ONLY ============================================================
      unless Rails.env == 'production'
        api.sandbox_update_request(request_current['request_id'], {status: 'accepted'})
        request_current = api.request_current
        request_current['driver']['phone_number'] = '(+84)1675444899'
      end
      # ========================================================================
      set_question nil
      current_ride.update(request_id: request_current['request_id'], active: false)
      send_message MessageTemplate.ride_found(request_current)
    end
  end

  def status_request_current
    request_current = api.request_current

    if request_current['errors']
      request_current['errors'].each do |error|
        case error['code']
        when 'no_current_trip'
          send_message MessageTemplate.no_request_current
        else
          Rails.logger.error "[ERROR]: #{error}"
        end
      end
    else
      # SANBOX ONLY ================================================================================
      request_current['driver']['phone_number'] = '(+84)1675444899' unless Rails.env == 'production'
      # ============================================================================================
      request_current_map = api.map(request_current['request_id'])
      send_message MessageTemplate.status_request(request_current, request_current_map)
    end
  end

  def cancel_request_current
    request_current = api.request_current

    if request_current['errors']
      request_current['errors'].each do |error|
        case error['code']
        when 'no_current_trip'
          send_message MessageTemplate.no_request_current
        else
          Rails.logger.error "[ERROR]: #{error}"
        end
      end
    else
      api.delete_request_current
    end
  end

  def cancel_ride
    return unless current_question == 'confirm_ride'
    current_ride.destroy
    current_ride = nil
    set_question nil
    start
  end

  def help
    return login(__callee__) unless auth.login?
    send_message MessageTemplate.help_list
  end

  def history
    return login(__callee__) unless auth.login?
    display_history
  end

  def display_history
    ride_history = api.history

    # SANBOX ONLY ================================================================================
    start_city = {}
    start_city['display_name'] = 'San Francisco'
    start_city['latitude'] = 37.7749295
    start_city['longitude'] = -122.4194155

    history_test = {}
    history_test['status'] = 'completed'
    history_test['distance'] = 1.64691465
    history_test['request_time'] = 1428876188
    history_test['start_time'] = 1428876374
    history_test['end_time'] = 1428876927
    history_test['start_city'] = start_city
    history_test['request_id'] = '37d57a99-2647-4114-9dd2-c43bccf4c30b'
    history_test['product_id'] = '8d7386df-d99c-48fd-a628-ea65f859b0ab'

    ride_history = [history_test, history_test, history_test]
    # ============================================================================================

    if ride_history.any?
      ride_history.each_with_index do |ride, index|
        ride['product_name'] = api.product_name_by_id(ride['product_id'])
        send_message MessageTemplate.history(ride, index + 1)
      end
    else
      send_message MessageTemplate.no_history
    end
  end

  def bookmark
    return login(__callee__) unless auth.login?
    display_bookmarks
  end

  def display_bookmarks
    send_message MessageTemplate.bookmark_list(user.bookmarks)
  end

  def add_bookmark
    set_question 'bookmark_name'
    send_message MessageTemplate.request_bookmark_name
  end

  def request_bookmark_address
    set_question 'bookmark_address'
    send_message MessageTemplate.request_bookmark_address
  end

  def delete_bookmark(bookmark_id)
    bookmark = Bookmark.find(bookmark_id).destroy
    send_message MessageTemplate.delete_bookmark_successfully(bookmark)
  end

  def feedback
    return login(__callee__) unless auth.login?
    set_question 'feedback'
    send_message MessageTemplate.request_feedback
  end
end
