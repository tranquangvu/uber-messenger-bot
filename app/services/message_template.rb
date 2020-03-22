class MessageTemplate
  def self.welcome
    {
      text: 'Welcome to Uber Bot. Press Ride to request a pickup. After requesting for pick up, enter pick up location and destination. If you need help at any point in time do press the Help button below.',
      quick_replies: [
        Messenger::SendApi.quick_reply(title: 'Ride'),
        Messenger::SendApi.quick_reply(title: 'Help'),
        Messenger::SendApi.quick_reply(title: 'History'),
        Messenger::SendApi.quick_reply(title: 'Bookmark'),
        Messenger::SendApi.quick_reply(title: 'Feedback')
      ]
    }
  end

  def self.login(url)
    {
      attachment: Messenger::SendApi.generic_template(
        elements: [Messenger::SendApi.generic_element(
          title: 'Sign in',
          image_url: image_url('account.jpg'),
          subtitle: 'Sign in your account and get moving in minutes',
          buttons: [Messenger::SendApi.button(type: 'account_link', url: url)]
        )]
      )
    }
  end

  def self.logged_in_successfully(callback)
    {
      text: 'Your account has been logged in successfully',
      quick_replies: [
        Messenger::SendApi.quick_reply(title: callback.capitalize),
        Messenger::SendApi.quick_reply(title: 'Home', payload: 'START')
      ]
    }
  end

  def self.logout
    {
      attachment: Messenger::SendApi.generic_template(
        elements: [Messenger::SendApi.generic_element(
          title: 'Sign out',
          image_url: image_url('account.jpg'),
          subtitle: 'Sign out your Uber account',
          buttons: [Messenger::SendApi.button(type: 'account_unlink')]
        )]
      )
    }
  end

  def self.logged_out_successfully
    { text: 'Your account has been logged out successfully' }
  end

  def self.request_location_by_attachment
    { text: 'Share your pick up location with us using the location icon menu from the keyboard' }
  end

  def self.attachment_guide
    {
      attachment: Messenger::SendApi.image(
        url: image_url('attachment_guide.gif')
      )
    }
  end

  def self.request_location_by_text
    {
      attachment: Messenger::SendApi.button_template(
        text: 'or simply type your postal code',
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'DISPLAY_BOOKMARK_TO_SELECT'),
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START')
        ]
      )
    }
  end

  def self.request_location_again
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Your input is not a valid location. Enter pick up location again, please!',
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'DISPLAY_BOOKMARK_TO_SELECT'),
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START')
        ]
      )
    }
  end

  def self.request_destination_by_attachment
    { text: 'Share your destination with us using the location icon menu from the keyboard' }
  end

  def self.request_destination_by_text
    {
      attachment: Messenger::SendApi.button_template(
        text: 'or simply type your postal code',
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'DISPLAY_BOOKMARK_TO_SELECT'),
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START')
        ]
      )
    }
  end

  def self.request_destination_again
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Your input is not a valid location. Enter destination again, please!',
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'DISPLAY_BOOKMARK_TO_SELECT'),
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START')
        ]
      )
    }
  end

  def self.product_list(products)
    elements = Array.new
    products.each{ |product| elements << product_element(product) }
    return_msg = { attachment: Messenger::SendApi.generic_template(elements: elements) }
  end

  def self.estimated_price(estimated_price, product)
    text = "This is the estimated fare #{estimated_price['estimate']} for #{product}.\n"
    text << "There is a surge pricing of #{estimated_price['surge_multiplier']}x" if estimated_price['surge_multiplier'] > 1.0

    return_msg = {
      attachment: Messenger::SendApi.button_template(
        text: text,
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: "Request #{product}", payload: 'CONFIRM_RIDE'),
          Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'CANCEL_RIDE')
        ]
      )
    }
  end

  def self.help_list
    {
      attachment: Messenger::SendApi.generic_template(
        elements: [
          help_ride_element,
          help_history_element,
          help_bookmark_element,
          help_feedback_element
        ]
      )
    }
  end

  def self.bookmark_list_to_select(bookmarks)
    return {
      attachment: Messenger::SendApi.button_template(
        text: 'There are no bookmarks. Please enter again by address, postal code or sent location via chat app',
        buttons: [Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START')]
      )
    } if bookmarks.empty?

    elements = Array.new
    bookmarks.each{ |bookmark| elements << bookmark_list_to_select_element(bookmark) }
    return_msg = { attachment: Messenger::SendApi.generic_template({elements: elements}) }
  end

  def self.bookmark_list(bookmarks)
    return {
      attachment: Messenger::SendApi.button_template(
        text: 'There are no bookmarks',
        buttons: [Messenger::SendApi.button(type: 'postback', title: 'Add Bookmark', payload: 'ADD_BOOKMARK')]
      )
    } if bookmarks.empty?

    elements = Array.new
    bookmarks.each{ |bookmark| elements << bookmark_list_element(bookmark) }
    return_msg = { attachment: Messenger::SendApi.generic_template({ elements: elements }) }
  end

  def self.history(user_history, index)
    {
      text: "#{index}. Pick up: #{user_history['start_city']['display_name']}\n" +
            "    Distance: #{user_history['distance'].round(2)} mile\n" +
            "    Start time: #{Time.at(user_history['start_time']).strftime('%m-%e-%y %H:%M')}\n" +
            "    End time: #{Time.at(user_history['end_time']).strftime('%m-%e-%y %H:%M')}\n" +
            "    Product: #{user_history['product_name']}"
    }
  end

  def self.no_history
    { text: "There is no ride taken." }
  end

  def self.unknow
    { text: "Sorry! I don't know what you mean. Press Help button in the menu for more information" }
  end

  def self.request_bookmark_name
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Please enter bookmark name',
        buttons: [Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'START')]
      )
    }
  end

  def self.request_bookmark_address
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Please enter bookmark address',
        buttons: [Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'START')]
      )
    }
  end

  def self.create_bookmark_successfully(bookmark)
    {
      attachment: Messenger::SendApi.button_template(
        text: "Bookmark #{bookmark.name} has been created successfully",
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START'),
          Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
        ]
      )
    }
  end

  def self.create_bookmark_unsuccessfully(bookmark_name)
    { text: "Bookmark #{bookmark.name} can't be saved. Please try again." }
  end

  def self.delete_bookmark_successfully(bookmark_name)
    {
      attachment: Messenger::SendApi.button_template(
        text: "Bookmark #{bookmark.name} has been deleted successfully",
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START'),
          Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
          Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
        ]
      )
    }
  end

  def self.finding_ride
    { text: 'Finding a ride for you. Please wait....' }
  end

  def self.request_product
    { text: 'Choose one of the rides below.' }
  end

  def self.no_product
    { text: 'Sorry! There are no product for your request.' }
  end

  def self.request_feedback
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Please enter your feedback content',
        buttons: [Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'START')]
      )
    }
  end

  def self.create_feedback_successfully
    {
      attachment: Messenger::SendApi.button_template(
        text: 'Your feedback has been created successfully',
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Home', payload: 'START'),
          Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE')
        ]
      )
    }
  end

  def self.create_feedback_unsuccessfully
    { text: "Your feedback can't be saved. Please try again." }
  end

  def self.ride_found(request_current)
    {
      attachment: Messenger::SendApi.button_template(
        text: "We have found a ride for you. #{request_current['vehicle']['license_plate']} is on the way.\n\n👉 Note: Cancel request is only free before 5 minutes.",
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Status', payload: 'STATUS_REQUEST_CURRENT'),
          Messenger::SendApi.button(type: 'phone_number', title: 'Call', payload: request_current['driver']['phone_number'].gsub(/\(|\)/, '')),
          Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'CANCEL_REQUEST_CURRENT')
        ]
      )
    }
  end

  def self.status_request(request_current, request_current_map)
    {
      attachment: Messenger::SendApi.button_template(
        text: "⚡ Driver: #{request_current['driver']['name']}\n" +
              "   👉 Phone: #{request_current['driver']['phone_number']}\n" +
              "   👉 Rating: #{request_current['driver']['rating']}\n" +
              "⚡ Vehicle: #{request_current['vehicle']['make']} #{request_current['vehicle']['model']}\n" +
              "   👉 License Plate: #{request_current['vehicle']['license_plate']}\n" +
              "⚡ Map: \n" +
              "   👉 Link: #{request_current_map['href']}",
        buttons: [
          Messenger::SendApi.button(type: 'postback', title: 'Status', payload: 'STATUS_REQUEST_CURRENT'),
          Messenger::SendApi.button(type: 'phone_number', title: 'Call', payload: request_current['driver']['phone_number'].gsub(/\(|\)/, '')),
          Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'CANCEL_REQUEST_CURRENT')
        ]
      )
    }
  end

  def self.no_request_current
    { text: 'You are not currently on a trip.' }
  end

  def self.request_payment_method
    { text: 'Choose a payment method' }
  end

  def self.payment_method_list(payment_methods)
    elements = Array.new
    payment_methods.each{ |payment_method| elements << payment_method_element(payment_method) }
    return_msg = { attachment: Messenger::SendApi.generic_template(elements: elements) }
  end

  def self.surge_confirmation(surge_confirmation_info)
    {
      attachment: Messenger::SendApi.button_template(
        text: "Surge pricing is current at #{surge_confirmation_info['multiplier']}x.",
        buttons: [
          Messenger::SendApi.button(type: 'web_url', title: 'I accept higher fare', url: surge_confirmation_info['href']),
          Messenger::SendApi.button(type: 'postback', title: 'Cancel', payload: 'CANCEL_RIDE')
        ]
      )
    }
  end

  private

  def self.image_url(image_path)
    path = Rails.application.assets.find_asset(image_path) ? image_path : 'default.jpg'
    Rails.application.secrets.domain_url + ActionController::Base.helpers.image_path(path)
  end

  def self.product_element(product)
    Messenger::SendApi.generic_element(
      title: product['display_name'],
      image_url: image_url("products/#{product['display_name'].downcase.sub('uber', '')}.jpg"),
      subtitle: product['description'].capitalize,
      buttons: [Messenger::SendApi.button(
        type: 'postback',
        payload: "SELECT_PRODUCT(#{product['display_name']},#{product['product_id']})",
        title: 'Select'
      )]
    )
  end

  def self.payment_method_element(payment_method)
    Messenger::SendApi.generic_element(
      title: Payment.payment_methods[payment_method['type'].to_sym],
      image_url: image_url("payment_methods/#{payment_method['type']}.jpg"),
      subtitle: payment_method['type'] == 'cash' ? 'CASH' : "PERSONAL #{payment_method['description']}",
      buttons: [Messenger::SendApi.button(
        type: 'postback',
        payload: "SELECT_PAYMENT_METHOD(#{payment_method['type']},#{payment_method['payment_method_id']})",
        title: 'Select'
      )]
    )
  end

  def self.help_ride_element
    Messenger::SendApi.generic_element(
      title: 'Ride',
      image_url: image_url('help_ride.jpg'),
      subtitle: 'Request ride by enter your location and destination',
      buttons: [
        Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
        Messenger::SendApi.button(type: 'postback', title: 'History', payload: 'HISTORY'),
        Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
      ]
    )
  end

  def self.help_history_element
    Messenger::SendApi.generic_element(
      title: 'History',
      image_url: image_url('help_history.jpg'),
      subtitle: 'Allows you to see the history of yours ride and the fare you paid',
      buttons: [
        Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
        Messenger::SendApi.button(type: 'postback', title: 'History', payload: 'HISTORY'),
        Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
      ]
    )
  end

  def self.help_bookmark_element
    Messenger::SendApi.generic_element(
      title: 'Bookmark',
      image_url: image_url('help_bookmark.jpg'),
      subtitle: 'It show the list of bookmarks of your favorite location',
      buttons: [
        Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
        Messenger::SendApi.button(type: 'postback', title: 'History', payload: 'HISTORY'),
        Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
      ]
    )
  end

  def self.help_feedback_element
    Messenger::SendApi.generic_element(
      title: 'Feedback',
      image_url: image_url('help_feedback.jpg'),
      subtitle: 'Send us what futures you would like to see or report any bugs in one message',
      buttons: [
        Messenger::SendApi.button(type: 'postback', title: 'Ride', payload: 'RIDE'),
        Messenger::SendApi.button(type: 'postback', title: 'History', payload: 'HISTORY'),
        Messenger::SendApi.button(type: 'postback', title: 'Bookmark', payload: 'BOOKMARK')
      ]
    )
  end

  def self.bookmark_list_to_select_element(bookmark)
    Messenger::SendApi.generic_element(
      title: bookmark.name,
      image_url: image_url('bookmark.jpg'),
      subtitle: bookmark.address,
      buttons: [Messenger::SendApi.button(type: 'postback', title: 'Select', payload: "SELECT_BOOKMARK(#{bookmark.address})")]
    )
  end

  def self.bookmark_list_element(bookmark)
    Messenger::SendApi.generic_element(
      title: bookmark.name,
      image_url: image_url('bookmark.jpg'),
      subtitle: bookmark.address,
      buttons: [
        Messenger::SendApi.button(type: 'postback', title: 'Delete bookmark', payload: "DELETE_BOOKMARK(#{bookmark.id})"),
        Messenger::SendApi.button(type: 'postback', title: 'Add bookmark', payload: "ADD_BOOKMARK")
      ]
    )
  end
end
