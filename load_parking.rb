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

def self.insert_stmt(db)
  db.prepare <<SQL
INSERT INTO Parking2014
VALUES (:ParkingEventId,
        :DeviceId,
        :ArrivalTime,
        :ArrivalTimeSeconds,
        :ArrivalDayOfWeek,
        :ArrivalDayOfMonth,
        :ArrivalMonth,
        :ArrivalYear,
        :DepartureTime,
        :DepartureTimeSeconds,
        :DepartureDayOfWeek,
        :DepartureDayOfMonth,
        :DepartureMonth,
        :DepartureYear,
        :Duration,
        :PermittedDuration,
        :StreetMarker,
        :SignPlateId,
        :Sign,
        :Area,
        :AreaName,
        :StreetId,
        :StreetName,
        :BetweenStreet1Id,
        :BetweenStreet1Description,
        :BetweenStreet2Id,
        :BetweenStreet2Description,
        :SideOfStreet,
        :SideCode,
        :SideName,
        :BayID,
        :InViolation);
SQL
end

def self.permitted_duration(sign)
  if m = sign.match(/^P[\/ ]{0,2}(\d+)/)
    m[1] * SECONDS_IN_MINUTE
  elsif m = sign.match(/^(\d)\s?P/)
    m[1] * SECONDS_IN_HOUR
  elsif sign[0..3] == '1/2P'
    SECONDS_IN_HOUR / 2
  elsif sign[0..3] == '1/4P'
    SECONDS_IN_HOUR / 4
  else
    0
  end
end

def self.insert_row(stmt, row)
  arrival_dt = DateTime.parse(row.fetch('ArrivalTime'))
  departure_dt = DateTime.parse(row.fetch('DepartureTime'))
  duration = (departure_dt - arrival_dt) * SECONDS_IN_DAY

  stmt.bind_param(:ParkingEventId, row.fetch('ParkingEventId'))
  stmt.bind_param(:DeviceId, row.fetch('DeviceId'))
  stmt.bind_param(:ArrivalTime, row.fetch('ArrivalTime'))
  stmt.bind_param(:ArrivalTimeSeconds, seconds_since_midnight(arrival_dt).to_i)
  stmt.bind_param(:ArrivalDayOfWeek, arrival_dt.wday)
  stmt.bind_param(:ArrivalDayOfMonth, arrival_dt.day)
  stmt.bind_param(:ArrivalMonth, arrival_dt.month)
  stmt.bind_param(:ArrivalYear, arrival_dt.year)
  stmt.bind_param(:DepartureTime, row.fetch('DepartureTime'))
  stmt.bind_param(:DepartureTimeSeconds, seconds_since_midnight(departure_dt).to_i)
  stmt.bind_param(:DepartureDayOfWeek, departure_dt.wday)
  stmt.bind_param(:DepartureDayOfMonth, departure_dt.day)
  stmt.bind_param(:DepartureMonth, departure_dt.month)
  stmt.bind_param(:DepartureYear, departure_dt.year)
  stmt.bind_param(:Duration, duration.to_i)
  stmt.bind_param(:PermittedDuration, permitted_duration(row.fetch('Sign')))
  stmt.bind_param(:StreetMarker, row.fetch('StreetMarker'))
  stmt.bind_param(:SignPlateId, row.fetch('SignPlateId'))
  stmt.bind_param(:Sign, row.fetch('Sign'))
  stmt.bind_param(:Area, row.fetch('Area'))
  stmt.bind_param(:AreaName, row.fetch('AreaName'))
  stmt.bind_param(:StreetId, row.fetch('StreetId'))
  stmt.bind_param(:StreetName, row.fetch('StreetName'))
  stmt.bind_param(:BetweenStreet1Id, row.fetch('BetweenStreet1 Id'))
  stmt.bind_param(:BetweenStreet1Description, row.fetch('BetweenStreet1 Description'))
  stmt.bind_param(:BetweenStreet2Id, row.fetch('BetweenStreet2 Id'))
  stmt.bind_param(:BetweenStreet2Description, row.fetch('BetweenStreet2 Description'))
  stmt.bind_param(:SideOfStreet, row.fetch('SideOfStreet'))
  stmt.bind_param(:SideCode, row.fetch('SideCode'))
  stmt.bind_param(:SideName, row.fetch('SideName'))
  stmt.bind_param(:BayID, row.fetch('BayID'))
  stmt.bind_param(:InViolation, row.fetch('InViolation') == 'true' ? 1 : 0)

  stmt.execute
end

begin
  create_query = IO.read('parking-schema.sql')
  puts 'Opening DB'
  db = SQLite3::Database.open ARGV[0]
  puts 'Creating table'
  db.execute('DROP TABLE IF EXISTS Parking2014')
  db.execute(create_query)

  stmt = insert_stmt(db)
  inserted = 0
  puts "Parsing CSV (#{ARGV[1]})"
  CSV.foreach(ARGV[1], :headers => true) {|row|
    stmt.reset!
    insert_row(stmt, row)
    inserted += 1
    puts "#{inserted} rows processed" if (inserted % 10000) == 0
  }
rescue Exception => e
  puts e.display
  puts e.backtrace
ensure
  stmt.close if stmt
  db.close if db
end
