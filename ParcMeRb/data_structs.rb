module ParcMe
  StreetSegment = Struct.new(:street_name,:between_street_1,:between_street_2)

  DirectionalStreetSegment = Struct.new(:street_segment, :side_code)

  ParkingBay = Struct.new(:bay_id, :sign, :directional_street_segment)

  ParkingEvent = Struct.new(:parking_bay, :start_time, :end_time, :duration)

  BayHistory = Struct.new(:parking_bay, :parking_events)

  # need to produce bay_histories, organised by date, and then by directional street segment

  class DataStore
    def initialize
      @street_segments = {}
      @parking_bays    = {}
      @street_segments = {}
      @directional_street_segments = {}
    end

    def street_segment(street_name, between_street_1, between_street_2)
      key = [street_name, between_street_1, between_street_2]
      @street_segments[key] = StreetSegment.new(*key) unless @street_segments.has_key?(key)

      @street_segments.fetch(key)
    end

    def create_parking_event(street_name, between_street_1, between_street_2, side_code, bay_id, sign, start_time, end_time, duration)
      parking_bay = parking_bay(bay_id, street_name, between_street_1, between_street_2, side_code, sign)
      ParkingEvent.new(parking_bay, start_time, end_time, duration)
    end

    # is bay_id unique?
    def parking_bay(bay_id, street_name, between_street_1, between_street_2, side_code, sign)
      bay_data = [bay_id, sign, directional_street_segment(street_name, between_street_1, between_street_2, side_code)]
      @parking_bays[bay_id] = ParkingBay.new(*bay_data) unless @parking_bays.has_key?(bay_id)
      @parking_bays.fetch(bay_id)
    end

    def directional_street_segment(street_name, between_street_1, between_street_2, side_code)
      dss_data = [street_segment(street_name, between_street_1, between_street_2),side_code]
      @directional_street_segments[dss_data] = DirectionalStreetSegment.new(*dss_data) unless @directional_street_segments.has_key?(dss_data)
      @directional_street_segments[dss_data]
    end

    def street_segment(street_name, between_street_1, between_street_2)
      ss_data = [street_name, between_street_1, between_street_2]
      @street_segments[ss_data] = StreetSegment.new(*ss_data) unless @street_segments.has_key?(ss_data)
      @street_segments.fetch(ss_data)
    end


  end
end