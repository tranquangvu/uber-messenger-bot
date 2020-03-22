class WebhookController < ApplicationController
  def verifier
    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == Rails.application.secrets.messenger['verify_token']
      render text: params['hub.challenge'], status: :ok
    end
  end

  def receiver
    Bot.new(params[:entry]).reply if params[:object] == 'page'
    render json: nil, status: :ok
  end

  def uber_status_change_receiver
    sender = User.find_by(uuid: params[:meta][:user_id])

    if params[:event_type] == 'requests.status_changed'
      status_changed_reply(params[:meta][:resource_id], params[:meta][:status], sender)
    end

    if params[:event_type] == 'requests.receipt_ready'
      receipt_ready_reply(params[:meta][:resource_id], params[:meta][:status], sender)
    end

    render json: nil, status: :ok
  end

  def uber_surge_confirmation
    sender_id = Ride.find_by(surge_confirmation_id: params[:surge_confirmation_id], active: true).user.messenger_id
    Bot.new([{
      messaging: [{
        sender: { id: sender_id },
        surge_confirmation: { surge_confirmation_id: params[:surge_confirmation_id] }
      }]
    }]).reply
    render text: 'Surge confirmation successfully!', status: :ok
  end

  private

  def status_changed_reply(resource_id, status, sender)
    text = case status
      when 'arriving'
        'Driver has arrived or will be shortly'
      when 'driver_canceled'
        'Your request has been canceled by the driver'
      when 'completed'
        'Your ride has been completed'
      when 'rider_canceled'
        'Your request has been canceled'
      else
        nil
    end
    MessengerReplyJob.perform_now(Messenger::SendApi.message(recipient_id: sender.messenger_id, message: { text: text })) if text
  end

  def receipt_ready_reply(resource_id, status, sender)
    return unless status == 'ready'

    receipt = Api.new(sender.access_token).receipt(resource_id)
    if receipt['distance'].to_f > 0
      text = "⚡ Receipt: \n" +
             "  👉 Distance: #{receipt['distance']} #{receipt['distance_label']}\n" +
             "  👉 Duration: #{receipt['duration']}\n" +
             "  👉 Total charge: #{receipt['total_charged']}"
    else
      text = "⚡ Receipt: \n" +
             "  👉 Cancel fee: #{receipt['total_charged']}"
    end
    MessengerReplyJob.perform_now(Messenger::SendApi.message(recipient_id: sender.messenger_id, message: { text: text }))
  end
end
