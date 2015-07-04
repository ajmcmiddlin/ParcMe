def hazard_data(events,max_mins)
  total_events = events.size
  still_going = events.dup

  (1..max_mins).map { |mins|
    secs = mins * 60
    start_size = still_going.size
    fails = still_going.select { |event|
      event.duration <= secs
    }.size

    still_going = still_going.select { |event|
      event.duration > secs
    }

    [mins, fails, start_size]
  }
end

def write_hazard_data(events,max_mins,dir)
  File.open(File.join(dir,'hazard_data.csv'),'w') { |file|
    file.puts 'mins, cumulative_fails, total_events'
    hazard_data(events,max_mins).each { |data|
      file.puts data.join(',')
    }
  }
end