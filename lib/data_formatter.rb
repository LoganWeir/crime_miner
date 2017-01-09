#!/usr/bin/env ruby

# def event_cleaner(raw_events, parameters)

#   cleaned_output = []

#   for item in raw_events

#     cleaned_event = {}

#     source = item['miner_data_source']

#     for key, value in parameters[source]['fields']

#       cleaned_event[key] = item[value]

#     end

#     cleaned_event['geo_data'] = item['rgeo_location']

#     if source == 'san_francisco'

#       raw_date = cleaned_event['date']
#       raw_time = cleaned_event['time']

#       # ruby_date = Date.new(raw_date)

#       # ruby_time = Time.parse(raw_time, ruby_date)

#       # puts ruby_time

    

#       # work_plz = clean_sf_time(raw_date, raw_time)

#     # else

#     #   puts cleaned_event['date']
#     #   puts cleaned_event['time']

#     end

#   end

# end



def layer_generator(cleaned_events)

  formatted_output = {}

  layer_id = 4868

  factory = RGeo::Geographic.simple_mercator_factory(:srid => 4326)

  # Build Layer
  layer_hash = {}
  layer_hash['name'] = "Recent Crimes in the Bay Area"
  layer_hash['id'] = layer_id

  # # NEED TO ADD layer_type (here, other data miners, and in Harvist)
  # layer_hash['layer_type'] = 'point'


  formatted_output['layer_data'] = layer_hash

  # Build Features
  feature_array = []

  for item in cleaned_events

    feature_hash = {}

    feature_hash['feature_id'] = id_generator()

    feature_hash['layer_id'] = layer_id

    # Fill color is just red for now
    feature_hash['fill_color'] = "#de2d26"

    # Need to modify Harvist API to accept zoom_level = 0
    # For now, this layer will only be visible if zoomed all the way out
    feature_hash['zoom_level'] = 13

    feature_hash['popup_title'] = "Recent Crime Reported"

    feature_hash['popup_description'] = crime_desciption_generator(item)

    feature_hash['geo_data'] = factory.collection([item['rgeo_location']])

    feature_array << feature_hash

  end

  formatted_output['feature_data'] = feature_array

  return formatted_output

end



# def ext_event_creator(raw_events)
# end

def crime_desciption_generator(event)

  cleaned_time = event['ruby_date_time'].strftime('%A %B %e, %Y, %H:%M')

  time = "Time: #{cleaned_time}" 

  description = "Description: #{event['ruby_description']}"

  output = time + "\n" + description

  return output

end



def id_generator()

  alpha_num = (('a'..'z').to_a + (0..9).to_a)
  
  id = (0..35).map { alpha_num[rand(alpha_num.length)] }.join

  return id

end
