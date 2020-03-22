class User < ApplicationRecord
  has_one  :conversation
  has_many :rides,     dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  def login?
    !access_token.nil?
  end

  def token_expired?
    Time.current > token_created_at + expires_in.seconds
  end

  def current_ride
    rides.where(active: true).first
  end

  def current_bookmark
    bookmarks.where(active: true).first
  end
end
