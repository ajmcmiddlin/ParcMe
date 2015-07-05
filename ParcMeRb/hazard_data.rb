def get_cdf_hash(events,max_secs, bin_size)
  total_events = events.select{|event| event.duration < max_secs }.size
  still_going = events.dup
  density = {}
  bin_lower_bound = 0
  (0..(max_secs/bin_size)).each { |bin_nr|
    bin_upper_bound_secs = bin_nr * bin_size
    density[bin_upper_bound_secs] = still_going.select { |event|
      event.duration <= bin_upper_bound_secs
    }.size / total_events.to_f
  }

  density
end

def calc_probability_for_duration_change(cdf_hash, initial_duration_secs, duration_change_secs)
  return 1 if initial_duration_secs > cdf_hash.keys.max

  initial_prob = calc_nearest_hash_value_for_duration(cdf_hash, initial_duration_secs).to_f
  return 1 if initial_prob == 1.0
  end_prob = calc_nearest_hash_value_for_duration(cdf_hash, initial_duration_secs+duration_change_secs).to_f

  (end_prob - initial_prob) / (1.0 - initial_prob)
end

def write_density_data(density_hash, dir)
  File.open(File.join(dir,'density_data.csv'),'w') { |file|
    file.puts 'time, density'
    density_hash.each { |time, density|
      file.puts [time, density].join(',')
    }
  }
end

def hazard_data(events,max_mins, bin_size)
  total_events = events.size
  still_going = events.dup

  (1..max_mins/bin_size).map { |mins|
    secs = mins * 60*bin_size
    start_size = still_going.size
    fails = still_going.select { |event|
      event.duration <= secs
    }.size

    still_going = still_going.select { |event|
      event.duration > secs
    }

    [secs, fails, start_size, fails.to_f/start_size.to_f]
  }
end

def get_hazard_hash(events, max_mins, bin_size)
  total_events = events.size
  still_going = events.dup

  hazard = {}
  (1..max_mins/bin_size).each { |mins|
    secs = mins * 60*bin_size
    start_size = still_going.size
    fails = still_going.select { |event|
      event.duration <= secs
    }.size

    still_going = still_going.select { |event|
      event.duration > secs
    }

    hazard[secs] = fails.to_f/start_size.to_f
  }

  hazard
end

def calc_nearest_hash_value_for_duration(hash, duration)
  previous_key = 0
  hash.fetch(duration) {|t|
    hash.keys.sort.each_with_index {|key, index|
      if index == 0
        previous_key = key
      else
        if key >= t
          if key - t > t - previous_key
            return hash[key]
          else
            return hash[previous_key]
          end
        end

        previous_key = key
      end
    }
    hash[previous_key]
  }
end

def write_hazard_data(events,max_mins, interval_size, dir)
  File.open(File.join(dir,'hazard_data.csv'),'w') { |file|
    file.puts 'mins, cumulative_fails, total_events, hazard'
    hazard_data(events,max_mins, interval_size).each_with_index { |data, index|
      next if index == 0
      file.puts data.join(',')
    }
  }
end

def write_hazard_function_output(directory, hazard_hash)
  File.open(File.join(directory, 'hazard_function_output.csv'), 'w') { |file|
    hazard_hash.keys.each { |key|
      file.puts [key, calc_nearest_hash_value_for_duration(hazard_hash, key)].join(',')
    }
  }
end

def cox_input_data(events,max_mins, interval_size)
  total_events = events.size
  events_set = events.dup.zip(1..total_events)
  data = []
  (1..max_mins/interval_size).map { |mins|
    new_events_set = []
    secs = mins * 60*interval_size

    events_set.each { |event|
      if event.first.duration <= secs
        data << [event.last, secs, 1]
      else
        data << [event.last, secs, 0]
        new_events_set << event
      end
    }
    events_set = new_events_set
  }

  data
end

def write_cox_data(events,max_mins, interval_size,dir)
  File.open(File.join(dir,'cox_data.csv'),'w') { |file|
    file.puts 'ID, time, status'
    cox_input_data(events,max_mins, interval_size).each_with_index { |data, index|
      next if index == 0
      file.puts data.join(',')
    }
  }
end