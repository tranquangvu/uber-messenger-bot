class Messenger::SendApi
  def self.message(recipient_id:, message:)
    {recipient: {id: recipient_id}, message: message}
  end

  def self.quick_reply(content_type: 'text', title: , payload: nil)
    {content_type: content_type, title: title, payload: payload || title.upcase.gsub(' ', '_')}
  end

  def self.generic_template(elements:)
    {type: 'template', payload: {template_type: 'generic', elements: elements}}
  end

  def self.generic_element(title:, item_url: nil, image_url: nil, subtitle: nil, buttons: nil)
    {title: title, item_url: item_url, image_url: image_url, subtitle: subtitle, buttons: buttons}.delete_if{ |key, value| value.nil? }
  end

  def self.button_template(text:, buttons:)
    {type: 'template', payload: {template_type: 'button', text: text, buttons: buttons}}
  end

  def self.button(type:, title: nil, url: nil, payload: nil)
    button           = {type: type}
    button[:title]   = title unless type == 'account_link' || type == 'account_unlink'
    button[:url]     = url if type == 'web_url' || type == 'account_link'
    button[:payload] = payload if type == 'postback' || type == 'phone_number'
    button
  end

  def self.image(url:)
    { type: 'image', payload: { url: url } }
  end
end
