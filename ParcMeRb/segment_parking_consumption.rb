require_relative 'data_processing'

DirSegmentConsumption = Struct.new(:capacity,:consumption_by_min)

def write_consumption_dataset(events,directory)
  consumption = directional_segment_consumption(events)

  File.open(File.join(directory, 'consumption.csv'),'w') { |f|
    f.puts "street_name,between_street_1,between_street_2,side_code,capacity," + (0..(mins_in_day-1)).to_a.join(',')
    consumption.each { |day,day_h|
      day_h.each { |ss,ss_h|
        ss_h.each { |side_code,side_code_consumption|
          f.puts [ss.street_name,ss.between_street_1,ss.between_street_2,side_code,side_code_consumption.capacity, *side_code_consumption.consumption_by_min].join(',')
        }
      }
    }
  }
end

def directional_segment_consumption(events)
  hash = by_day_segment_direction_and_bay(events)
  hash.map_values { |_,day_h|
    day_h.map_values { |segment,segment_h|
      segment_h.map_values { |side,side_h|
        capacity = side_h.size
        consumption = empty()

        side_h.values.each { |bay_history|
          bay_consumption = parking_consumed(bay_history)
          consumption = consumption.zip(bay_consumption).map { |total,bay| total + bay }
        }
        DirSegmentConsumption.new(capacity,consumption)
      }
    }

  }
end

def parking_consumed(events)
  consumption = empty()
  events.each { |event|
    start_secs = secs_from_midnight(event.start_time.to_time)
    end_secs   = secs_from_midnight(event.end_time.to_time)

    start_secs.step(end_secs,60) { |consumed_secs|
      mins = (consumed_secs / 60).to_i
      consumption[mins] = 1
    }
  }
  consumption
end

def empty
  (1..mins_in_day).map { |_| 0.0 }
end

def mins_in_day
  60*24
end

def secs_from_midnight(time)
  (time.hour-10) * 3600 + time.min * 60 + time.sec
end