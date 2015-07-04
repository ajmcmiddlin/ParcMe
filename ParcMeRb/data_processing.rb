def by_day_segment_direction_and_bay(events)
  events.group_by { |event|
    event.start_time.to_date.to_s
  }.map_values { |_,day_events|
    day_events.group_by { |event|
      event.parking_bay.directional_street_segment.street_segment
    }.map_values { |_,segment_events|
      segment_events.group_by { |event|
        event.parking_bay.directional_street_segment.side_code
      }.map_values { |_,side_events|
        side_events.group_by { |event|
          event.parking_bay.bay_id
        }.map_values { |_,bay_events|
          bay_events.sort { |e1,e2|
            e1.start_time <=> e2.start_time
          }
        }
      }
    }
  }
end


