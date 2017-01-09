#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'data_requester'
require 'data_formatter'
require 'rabbitmq'

require 'net/http'
require 'json'
require 'uri'
require 'csv'
require 'date'
require 'time'

require 'bunny'
require 'sequel'
require 'pg'
require 'rgeo'


begin

  source_parameters = JSON.parse(File.read('crime_source_parameters.json'))

  # Connect to RabbitMQ
  # rabbitmq_connection = BunnyEmitter.new(ENV['RABBITMQ_URL'], "recent_crimes")

  # # DATABASE CRAP
  # # Connect to Harvist DB for Parameters
  # db = Sequel.postgres(ENV['DATABASE_NAME'],
  #                      user: ENV['DATABASE_USER'],
  #                      password: ENV['DATABASE_PASSWORD'],
  #                      host: ENV['DATABASE_HOST'],
  #                      port: 5432)


  # # FROM DB, GET:
  # # - CRIME LAYER LAST_UPDATE
  # # - POINTS OR AREAS OF INTERSECTION


  # CHECK HARVSIT DB FOR WEATHER HAZARDS LAYER UPDATED_AT
  # IF NIL or DIFFERENT, ADD INITIAL DATA

  puts "Getting Initial Recent Crimes"

  harvist_payload = []

  date_now = DateTime.now

  for key, value in source_parameters

    last_updated = check_update(value)

    # Change last_updated for looping
    value['last_updated'] = last_updated

   
    # Gets data
    data = get_update(value, last_updated)

    # Clean Geo data and Time data
    cleaned_data = clean_update(data, value)

    # Filter by Time and Duplicates
    filtered_data = filter_update(cleaned_data, date_now, value,
      harvist_payload)

  end



  # # FILTERS OUT NON-INTERSECTING EVENTS
  # # ADDS FIELD OF INTERSECTING DEVICEGROUPS
  # # intersecting_events = intersection_check(event, device_group_intersection)



  # Creates hash for adding to the Layer/Layer Features Table
  layer_output = layer_generator(harvist_payload)

  # # # Creates hash for adding to the External Events Tables
  # # external_events_output = ext_event_creator(harvist_payload)


  # # Used to checking event quantity
  # puts harvist_payload.length


  # ADD EVERYTHING TO DB

  # SEND RABBITMQ MESSAGE
  # rabbitmq_connection.publish("Recent Crimes Updated")





  # THEN LOOP

  while true

    sleep 20

    puts "Checking for Recent Crimes Update"

    harvist_payload = []

    date_now = DateTime.now

    # Check updates for each source
    for key, value in source_parameters

      last_updated = check_update(value)

      if value['last_updated'] != last_updated

        # Update
        value['last_updated'] = last_updated

        # Gets data
        data = get_update(value, last_updated)

        # Clean Geo data and Time data
        cleaned_data = clean_update(data, value)

        # Filter by Time and Duplicates
        filtered_data = filter_update(cleaned_data, date_now, value,
          harvist_payload)  

      end

    end

    # If updates, push to DB and Send Message
    if harvist_payload.length > 0

      puts "Change detected"

      # Creates hash for adding to the Layer/Layer Features Table
      layer_output = layer_generator(harvist_payload)

      # # Creates hash for adding to the External Events Tables
      # external_events_output = ext_event_creator(harvist_payload)

      # ADD EVERYTHING TO DB

      # # SEND RABBITMQ MESSAGE
      # rabbitmq_connection.publish("Recent Crimes Updated")    

    else

      puts "No Change"  

    end

  end

rescue Interrupt => _

  # Disconnect from Rabbit
  # rabbitmq_connection.close

  # DISCONNECT FROM DATABASE

  exit(0)

end

