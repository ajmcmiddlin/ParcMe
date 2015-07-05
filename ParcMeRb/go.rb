require_relative 'data_reader'
require_relative 'hazard_data'

directory = File.join(File.dirname(__FILE__),'..')
csv_file = '/Users/LaurenceNicol/Work/GovHack2015/ParcMe/Parking_Events_2014.csv'
# street_name, between_street_1, between_street_2, side_code, bay_id, sign, date, start_time, end_time
events = ParcMe::DataReader.read_parking_events_from_csv(csv_file, 100000) { |record|
  record.fetch("SignPlateId") == 6.to_s
}

class Hash
  def map_values
    self.merge(self) { |k,v1| yield(k,v1) }
  end
end

# hazard_hash = get_hazard_hash(events, 120, 1)
# puts calc_hazard_for_duration(hazard_hash, 3000)
cdf_hash = get_cdf_hash(events,10800,60)
puts cdf_hash.inspect
write_density_data(cdf_hash, directory)
write_hazard_data(events,180, 1, directory)
# write_cox_data(events, 120, 1, directory)
# by_day = by_day_segment_direction_and_bay(events)



