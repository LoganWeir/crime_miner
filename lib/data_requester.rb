#!/usr/bin/env ruby

def check_update(parameter_hash)

  order_by = "$order=:updated_at DESC"
  limit = "$limit=1"
  select_updated = "$select=:updated_at"

  request_url = [parameter_hash['base_url'], parameter_hash['token'], order_by, 
    limit, select_updated].join('&')

  data = request_data(request_url)

  last_updated = data[0][":updated_at"]

  return last_updated

end




def get_update(parameter_hash, last_update)

  select_all = "$select=:*, *"

  where = "$where=:updated_at = '#{last_update}'"

  request_url = [parameter_hash['base_url'], parameter_hash['token'], 
    select_all, where].join('&')

  data = request_data(request_url)

  return data

end





# Clean RGEO, Update Source, Update Time
def clean_update(data, parameter_hash)

  factory = RGeo::Geographic.simple_mercator_factory(:srid => 4326)

  for item in data

    # Record event source
    item['miner_data_source'] = parameter_hash['source']


    # Clean Location Data for filtering before formatting
    raw_location = item[parameter_hash['location']]

    longitude = raw_location['coordinates'][0]
    latitude = raw_location['coordinates'][1]

    rgeo_point = factory.point(longitude, latitude)

    item['rgeo_location'] = factory.collection([rgeo_point])


    # Clean Time Field
    if parameter_hash['source'] == 'san_francisco'

      time = Time.strptime(item['time'], '%H:%M')
      date = DateTime.parse(item['date'])

      item['ruby_date_time'] = DateTime.new(date.year, date.month, 
        date.day, time.hour, time.min, time.sec, time.zone)

    # Other 2 timefields are uniform
    else

      date_key = parameter_hash['fields']['date']

      no_utc_time = DateTime.parse(item[date_key])

      item['ruby_date_time'] = no_utc_time.new_offset('-08:00')

    end

  end

  return data

end

  


def filter_update(data, date_now, parameter_hash, array)

  # Filter out event older than 30 days from now
  time_filtered = []

  for item in data

    if item['ruby_date_time'] > date_now - 30

      time_filtered << item

    end

  end

  # Merge duplicates
  # First, array of ID's
  id_array = []

  for item in time_filtered

    id_array << item[parameter_hash['fields']['incident_id']]

  end


  # Find Duplicates
  all_dups = id_array.select{ |dup| id_array.count(dup) > 1 }

  uniq_dups = all_dups.uniq


  # Create hash grouping duplicates together
  duplicate_hash = {}

  for duplicate_id in uniq_dups
    duplicate_hash[duplicate_id] = []
  end


  # Filter Duplicates into a hash
  for item in time_filtered

    item_id = item[parameter_hash['fields']['incident_id']]

    if uniq_dups.include?(item_id)

      duplicate_hash[item_id] << item

    else

      # Non-duplicates into final array after cleaning description

      item['ruby_description'] = item[parameter_hash['fields']['description']]

      array << item

    end

  end

  # Merge Duplicate Event
  for key, value in duplicate_hash

    first_duplicate = value.shift

    descrip = first_duplicate[parameter_hash['fields']['description']]

    # Merge Descriptions
    for remainder in value

      extra_descrip = remainder[parameter_hash['fields']['description']]

      descrip += ", #{extra_descrip}"

    end

    first_duplicate[parameter_hash['fields']['description']] = descrip

    first_duplicate['ruby_description'] = descrip

    # Add Single to Array
    array << first_duplicate

  end

end




# def intersection_check(raw_events, device_groups)
# end




def request_data(request_url)

  uri = URI.parse(request_url)
  response = Net::HTTP.get_response(uri)
  data = JSON.parse(response.body)
  return data

end