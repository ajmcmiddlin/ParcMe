def hazard_data(events,max_mins, interval_size)
  total_events = events.size
  still_going = events.dup

  (1..max_mins/interval_size).map { |mins|
    secs = mins * 60*interval_size
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

def write_hazard_data(events,max_mins, interval_size, dir)
  File.open(File.join(dir,'hazard_data.csv'),'w') { |file|
    file.puts 'mins, cumulative_fails, total_events, hazard'
    hazard_data(events,max_mins, interval_size).each { |data|
      file.puts data.join(',')
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
    cox_input_data(events,max_mins, interval_size).each { |data|
      file.puts data.join(',')
    }
  }
end