require_relative 'data_structs'
require 'Date'

module ParcMe
  class DataReader
    def self.read_parking_events_from_csv(csv_file, num_records, &blk)
      store = DataStore.new
      parking_events = nil
      File.open(csv_file,'r') { |file_h|
        header = file_h.readline.strip.split(',')
        parking_events = (1..num_records).map { |line|
          row = file_h.readline.strip.gsub(/\"/,'').split(',')
          h = Hash[*(header.zip(row).flatten)]

          next unless !block_given? || yield(h)

          # street_name, between_street_1, between_street_2, side_code, bay_id, sign, start_time, end_time
          pe_data = ['StreetName','BetweenStreet1Description','BetweenStreet2Description','SideCode','BayID','Sign'].map { |field|
            h.fetch(field)
          }
          #arrival_time = h.fetch('ArrivalTime')
          #departure_time = h.fetch('DepartureTime')
          p h.fetch('ArrivalTime')
          time_str = '%d/%m/%Y %H:%M:%S %p +0000'
          arrival_time = DateTime.strptime("13/03/2014 12:01:16 AM +0000",'%d/%m/%Y %H:%M:%S %p +0000')
          # arrival_time = DateTime.strptime(h.fetch('ArrivalTime'),time_str)
          departure_time = DateTime.strptime(h.fetch('DepartureTime'),time_str)

          pe_data += [arrival_time, departure_time, (departure_time - arrival_time) * 24.0 * 3600]

          store.create_parking_event(*pe_data)
        }.compact
      }
      raise "no parking events!" unless parking_events
      parking_events
    end

    ParcMeDate = Struct.new(:day,:month,:year) {
      def to_s
        [day,month,year].join('/')
      end
    }
    def self.get_date(date_time_string)
      date_time_string =~ /([0-9]+)\/([0-9]+)\/([0-9]+)\s/
      ParcMeDate.new($1, $2, $3)
    end

    ParcMeTime = Struct.new(:hours,:mins,:secs) {
      def secs_from_midnight()
        hours * 3600 + mins * 60 + secs
      end
    }
    def self.get_time(date_time_string)
      date_time_string =~ /\s([0-9]+)\:([0-9]+)\:([0-9]+)\s/
      ParcMeTime.new($1.to_i, $2.to_i, $3.to_i)
    end
  end
end