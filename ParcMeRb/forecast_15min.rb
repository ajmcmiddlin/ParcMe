require_relative 'data_reader'
require_relative 'hazard_data'
require_relative 'ot_import'
require_relative 'segment_parking_consumption'

directory = File.join(File.dirname(__FILE__),'..')
csv_file = '/Users/timveitch/Documents/Learning/ParcMe/parking-20140313.csv'
# street_name, between_street_1, between_street_2, side_code, bay_id, sign, date, start_time, end_time
events = ParcMe::DataReader.read_parking_events_from_csv(csv_file, 38519)

def write_expected_free_spaces(expected_free_spaces,directory)
  header = 'day,street_name,between_street_1,between_street_2,side_code,' + (0..(mins_in_day / 15 - 1)).to_a.join(',')
  File.open(File.join(directory, 'forecast_free_spaces.csv'),'w') { |file|
    file.puts header
    expected_free_spaces.each { |day,seg_h|
      seg_h.each { |seg,side_h|
        side_h.each { |side_code,free_spaces_vec|
          data = [day,seg.street_name,seg.between_street_1,seg.between_street_2,side_code] + free_spaces_vec
          file.puts data.join(',')
        }
      }
    }
  }
end

def expected_free_spaces(events,global_demand_rate)
  massive_nested_hash = by_day_segment_direction_and_bay(events)

  cdf = get_cdf_hash(events,10800,60)

  massive_nested_hash.map_values { |day,segment_h|
    total_parks = segment_h.values.map { |side_code_h|
      side_code_h.values.map { |bay_h|
        bay_h.keys.size
      }.inject(0) { |acc,e| acc + e }
    }.inject(0) { |acc,e| acc + e }
    puts "Total parks #{total_parks}"

    segment_h.map_values { |segment,side_code_h|
      side_code_h.map_values { |side_code, bay_h|
        (0..(mins_in_day / 15 -1)).map { |interval|
          start_secs = interval * 900

          freed_spaces = bay_h.values.map { |bay_events|
            events = find_event_at_time(bay_events,start_secs)
            if events.empty?
              1
            elsif
              event = events.first
              how_long_so_far = start_secs - secs_from_midnight(event.start_time.to_time)
              #p "hlsf #{how_long_so_far}"
              prob_depart = calc_probability_for_duration_change(cdf, how_long_so_far, 15*60)
              #p "prob_depart #{prob_depart}"
              prob_depart
            end
          }.inject(0.0) { |acc,val| val + acc }
          
          [freed_spaces - global_demand_rate.fetch(interval).to_f * bay_h.keys.size / total_parks,0].max
        }
      }
    }
  }
end

def find_event_at_time(bay_events,start_secs)
  matches = bay_events.select { |event|
    secs_from_midnight(event.start_time.to_time) <= start_secs && secs_from_midnight(event.end_time.to_time) > start_secs
  }
  raise "too many matches" if matches.size > 1
  matches
end

def read_global_demand_rate(demand_file)
  File.open(demand_file, 'r') { |file|
    file.readline
    h = {}
    file.readlines.map { |line|
      interval, demand = line.strip.split(',').map(&:to_i)
      h[interval] = demand
    }
  }
end