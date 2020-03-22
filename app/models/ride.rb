class Ride < ApplicationRecord
  belongs_to :user  
  after_validation :generate_geocode

  private
  
  def generate_geocode
    self.location_latitude, self.location_longitude       = Geocoder.coordinates(location) unless location.nil?
    self.destination_latitude, self.destination_longitude = Geocoder.coordinates(destination) unless destination.nil?
  end
end
