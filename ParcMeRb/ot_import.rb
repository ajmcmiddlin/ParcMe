ConsumptionData = Struct.new(:street_name,:boundary_street_1,:boundary_street_2,:side_code,:capacity,:consumption_by_min)

class OtConsumptionDataImporter

  def initialize
    sql = (<<-SQL)
SELECT l112.linknr,l112.direction,betweenstreet1,betweenstreet2,l112.side_code
FROM 'link1data1' l11, 'link1_1data2' l112
WHERE l11.linknr = l112.linknr
SQL
     records = OtQuery.execute_to_a(sql)

     @boundaries_and_side_to_linkset = records.group_by { |(linknr,dirn,b1,b2,side_code)|
      boundary_side_key(b1,b2,side_code)
     }.map_values { |_,links|
      links.map { |(linknr,dirn,b1,b2,side_code)|
        [linknr,dirn]
      }
     }
  end

  def import_consumption_data(consumption_file)
    consumption_data = read_consumption_file(consumption_file)
    p consumption_data.size
    data = make_link5_data(consumption_data)
    p data.size
    OtQuery.execute("DELETE FROM 'link5_2data1'")

    OtTable.insert(File.join($Ot.variantDirectory,'link5_2data1.db'),data)
  end

  def make_link5_data(consumption_data)
    consumption_data.flat_map { |record|
      link_set = if record.side_code == 'C'
                   get_center_link_set(record.street_name, record.boundary_street_1, record.boundary_street_2)
                 else
                   get_directional_link_set(record.street_name, record.boundary_street_1, record.boundary_street_2, record.side_code)
                 end
      link_set.flat_map { |(linknr,direction)|
        record.consumption_by_min.map_with_index { |consumption,min|
          scale_factor = record.side_code == 'C' ? 0.5 : 1.0
          [linknr,1,1,min+1,1,1,1,direction,0,consumption.to_f * scale_factor,record.capacity.to_f*scale_factor,(record.capacity.to_f-consumption.to_f) * scale_factor]
        }
      }
    }

  end

  def get_center_link_set(street_name, boundary_street_1, boundary_street_2)
    links_with_name = $Ot.network.links_with_name(street_name).flat_map { |linknr| [[linknr,1],[linknr,2]] }
    between_links = ['N','S','E','W'].flat_map { |side_code|
      get_links_for_boundary_and_side(boundary_street_1,boundary_street_2,side_code)
    }.uniq
    links_with_name & between_links
  end

  def get_directional_link_set(street_name, boundary_street_1, boundary_street_2, side_code)
    links_with_name = $Ot.network.links_with_name(street_name).flat_map { |linknr| [[linknr,1],[linknr,2]] }
    p links_with_name if street_name == 'LONSDALE STREET'
    p get_links_for_boundary_and_side(boundary_street_1,boundary_street_2,side_code) if street_name == 'LONSDALE STREET'
    links_with_name & get_links_for_boundary_and_side(boundary_street_1,boundary_street_2,side_code)
  end

  def get_links_for_boundary_and_side(boundary_street_1, boundary_street_2, side_code)
    @boundaries_and_side_to_linkset.fetch(boundary_side_key(boundary_street_1, boundary_street_2, side_code),[])
  end

  def boundary_side_key(boundary_street_1, boundary_street_2, side_code)
    [[boundary_street_1,boundary_street_2].sort,side_code]
  end

  def read_consumption_file(consumption_file)
    consumption_data = nil
    File.open(consumption_file,'r') { |f|
      header     = f.readline.strip.split(',')

      zero_index = header.index('0')
      init_header = header[0..(zero_index-1)]
      consumption_data = f.readlines.map { |line|
        row              = line.strip.split(',')
        init_data        = row[0..(zero_index-1)]
        consumptions     = row[zero_index..-1].map(&:to_i)

        data = init_data + [consumptions]
        ConsumptionData.new(*data)
      }
    }
    consumption_data
  end

  def create_between_streets(events)
    path_builder = create_path_builder()
    records = events.map { |event|
      event.parking_bay.directional_street_segment.street_segment
    }.uniq.flat_map { |street_segment|
      street_links = $Ot.network.links_with_name(street_segment.street_name)
      street_nodes = get_node_set(street_links)
      crossing_links_1 = $Ot.network.links_with_name(street_segment.between_street_1)
      crossing_links_2 = $Ot.network.links_with_name(street_segment.between_street_2)

      crossing_nodes_1 = get_node_set(crossing_links_1)
      crossing_nodes_2 = get_node_set(crossing_links_2)

      #p street_nodes
      #p crossing_nodes_1
      #puts "STREET #{street_segment.street_name}"
      #puts "CROSS #{street_segment.between_street_1}"
      anode = find_matching_node(street_nodes, crossing_nodes_1)
      #puts "CROSS #{street_segment.between_street_2}"
      bnode = find_matching_node(street_nodes, crossing_nodes_2)

      next unless anode && bnode
      path = build_path(path_builder,anode,bnode)
      path_links = path.map(&:first)

      ordered_between = [street_segment.between_street_1,street_segment.between_street_2].sort
      path_links.map { |linknr|
        # TODO - check the fields
        [linknr,'','','',ordered_between.first,ordered_between.last]
      }
    }.compact

    uniq_records = records.group_by { |record| record.first }.map_values { |_,recs| recs.first }.values
    p uniq_records.map(&:first).uniq.length
    p uniq_records.size
    uniq_records.each { |record|
      p record
    }
    OtQuery.execute("DELETE FROM 'link1data1'")
    OtTable.insert($Ot.mainVariantDirectory / 'link1data1.db', uniq_records)
  end

  def create_path_builder
    # TODO: check this...
    traffic = ZenithHighway.new
    traffic.routeFactors = [1,0,0,0]

    user_class = User.new
    user_class.network = [M_Car,T_AM]

    traffic.addUserClass(M_Car,user_class)
    traffic.freezeProperties = true
    traffic
  end

  def build_path(path_builder,anode,bnode)
    links = path_builder.getPath(anode,bnode)
    if links.empty?
      links = path_builder.getPath(bnode,anode)
    end

    raise "No path found" if links.empty?
    links
  end

  def get_node_set(link_set)
    link_set.map { |linknr|
      $Ot.network.get_link_nodes(linknr)
    }.flatten.uniq
  end

  def find_matching_node(nodes1,nodes2)
    matches = nodes1 & nodes2
    return nil if matches.empty?
    raise "Too many matches!" if matches.size > 1
    matches.first
  end
end
