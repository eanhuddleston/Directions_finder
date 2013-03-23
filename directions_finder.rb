require 'rest-client'
require 'json'
require 'addressable/uri'
require 'nokogiri'

PLACES_API_KEY = "AIzaSyB-oVG56hx6mqORyo5K-WYtxOuw-sbwXGo"

def get_user_location
  puts "What is your current location (address or area code)?"
  gets.chomp.split(" ").join("+")
end

def get_desired_dest
  puts "Where would you like to go?"
  gets.chomp.split(" ").join("+")
end

def origin_lat_long(curr_address)
  origin_query = Addressable::URI.new(
     :scheme => "http",
     :host => "maps.googleapis.com",
     :path => "/maps/api/geocode/json",
     :query_values => {:address => curr_address, :sensor => false}
   ).to_s
  results = JSON.parse(RestClient.get(origin_query))["results"]
  results[0]["geometry"]["location"]
end

def get_businesses(origin_lat_long, desired_dest)
  places_query = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "/maps/api/place/nearbysearch/json",
     :query_values => {:location => "#{origin_lat_long["lat"]},#{origin_lat_long["lng"]}",
         :radius => 4000,
         :keyword => desired_dest,
         :sensor => false,
         :key => PLACES_API_KEY }).to_s
  JSON.parse(RestClient.get(places_query))
end

def display_businesses(businesses)
  businesses["results"].each_with_index do |bus, index|
    puts "#{index + 1}: #{bus["name"]}"
  end
  puts ""
end

def get_user_choice
  puts "Enter the number of the business you want:"
  gets.chomp.to_i - 1
end

def get_directions(origin, dest)
  directions_query = Addressable::URI.new(
     :scheme => "http",
     :host => "maps.googleapis.com",
     :path => "/maps/api/directions/json",
     :query_values => {:origin => "#{origin["lat"]},#{origin["lng"]}",
         :destination => "#{dest["lat"]},#{dest["lng"]}",
         :sensor => false,
         :mode => "walking"}).to_s
  JSON.parse(RestClient.get(directions_query))
end

def print_directions(directions)
  tot_dist = directions["routes"][0]["legs"][0]["distance"]["text"]
  tot_time = directions["routes"][0]["legs"][0]["duration"]["text"]
  bus_address = directions["routes"][0]["legs"][0]["end_address"]

  puts ""
  puts "Directions to #{bus_address}:"
  puts "Total distance: #{tot_dist}, Total time: #{tot_time}"

  steps = directions["routes"][0]["legs"][0]["steps"]
  steps.each_with_index do |step, i|
    #puts "Step #{i + 1}:"
    parsed_html = Nokogiri::HTML(step["html_instructions"])
    puts "#{i}. #{parsed_html.text}"
    puts "  (Distance: #{step["distance"]["text"]}, Duration: #{step["duration"]["text"]})"
  end
end

curr_address = get_user_location
desired_dest = get_desired_dest

origin_lat_long = origin_lat_long(curr_address)
businesses = get_businesses(origin_lat_long, desired_dest)
display_businesses(businesses)

user_choice = get_user_choice

business_lat_long = businesses["results"][user_choice]["geometry"]["location"]
business_name = businesses["results"][user_choice]["name"]
walk_dirs = get_directions(origin_lat_long, business_lat_long)
print_directions(walk_dirs)








