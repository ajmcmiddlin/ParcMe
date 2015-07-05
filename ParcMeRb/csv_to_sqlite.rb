#!/usr/bin/env ruby

require 'csv'
require 'sqlite3'
require 'date'

SECONDS_IN_MINUTE = 60
SECONDS_IN_HOUR = SECONDS_IN_MINUTE * 60
SECONDS_IN_DAY = SECONDS_IN_HOUR * 24

DateTimeBits = Struct.new(:seconds_since_midnight,
                          :day_of_week,
                          :day_of_month,
                          :month,
                          :year)

def self.seconds_since_midnight(dt)
  (dt - dt.to_date) * SECONDS_IN_DAY
end

def self.permitted_duration(sign)
  return 0 unless sign

  if m = sign.match(/^P[\/ ]{0,2}(\d+)/)
    m[1].to_i * SECONDS_IN_MINUTE
  elsif m = sign.match(/^(\d)\s?P/)
    m[1].to_i * SECONDS_IN_HOUR
  elsif sign[0..3] == '1/2P'
    SECONDS_IN_HOUR / 2
  elsif sign[0..3] == '1/4P'
    SECONDS_IN_HOUR / 4
  else
    0
  end
end

def self.headers
  %w{ParkingEventId DeviceId ArrivalTime ArrivalTimeSeconds ArrivalDayOfWeek ArrivalDayOfMonth
     ArrivalMonth ArrivalYear DepartureTime DepartureTimeSeconds DepartureDayOfWeek DepartureDayOfMonth
     DepartureMonth DepartureYear Duration PermittedDuration StreetMarker SignPlateId Sign Area AreaName
     StreetId StreetName BetweenStreet1Id BetweenStreet1Description BetweenStreet2Id BetweenStreet2Description
     SideOfStreet SideCode SideName BayID InViolation} 
end

def self.make_out_row(row)
  arrival_dt = DateTime.parse(row.fetch('ArrivalTime'))
  departure_dt = DateTime.parse(row.fetch('DepartureTime'))
  duration = (departure_dt - arrival_dt) * SECONDS_IN_DAY

  [
    row.fetch('ParkingEventId'),
    row.fetch('DeviceId'),
    row.fetch('ArrivalTime'),
    seconds_since_midnight(arrival_dt).to_i,
    arrival_dt.wday,
    arrival_dt.day,
    arrival_dt.month,
    arrival_dt.year,
    row.fetch('DepartureTime'),
    seconds_since_midnight(departure_dt).to_i,
    departure_dt.wday,
    departure_dt.day,
    departure_dt.month,
    departure_dt.year,
    duration.to_i,
    permitted_duration(row.fetch('Sign')),
    row.fetch('StreetMarker'),
    row.fetch('SignPlateId'),
    row.fetch('Sign'),
    row.fetch('Area'),
    row.fetch('AreaName'),
    row.fetch('StreetId'),
    row.fetch('StreetName'),
    row.fetch('BetweenStreet1 Id'),
    row.fetch('BetweenStreet1 Description'),
    row.fetch('BetweenStreet2 Id'),
    row.fetch('BetweenStreet2 Description'),
    row.fetch('SideOfStreet'),
    row.fetch('SideCode'),
    row.fetch('SideName'),
    row.fetch('BayID'),
    row.fetch('InViolation') == 'true' ? 1 : 0
  ]
end

begin
  TABLE_NAME = 'Parking2014'
  create_query = IO.read('parking-schema.sql')
  puts 'Opening DB'
  db = SQLite3::Database.open ARGV[0]
  db.execute("DROP TABLE IF EXISTS #{TABLE_NAME}")
  puts 'Creating table'
  db.execute(create_query)
  db.close

  puts "Parsing CSV (#{ARGV[1]})"
  inserted = 0
  OUTPUT_CSV = 'parking-processed.csv'
  CSV.open(OUTPUT_CSV, 'w') {|csv|
    csv << headers
    CSV.foreach(ARGV[1], :headers => true) {|row|
      row = make_out_row(row)
      csv << row
      inserted += 1
      puts "#{inserted} rows processed" if (inserted % 10000) == 0
    }
  }

  puts 'Importing CSV to SQLite'
  `sqlite3 -separator , #{ARGV[0]} ".import #{OUTPUT_CSV} #{TABLE_NAME}"`
rescue Exception => e
  puts e.display
  puts e.backtrace
ensure
  db.close if db
end
