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

def calc_hazard_for_duration(hazard_hash, duration)
  previous_key = 0
  hazard_hash.fetch(duration) {|t|
    hazard_hash.keys.sort.each_with_index {|key, index|
      puts index
      if index == 0
        previous_key = key
      else
        if key >= t
          if key - t > t - previous_key
            return hazard_hash[key]
          else
            return hazard_hash[previous_key]
          end
        end

        previous_key = key
      end
    }
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
      file.puts [key, calc_hazard_for_duration(hazard_hash, key)].join(',')
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