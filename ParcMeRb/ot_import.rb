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
    OtTable.insert(File.join($Ot.variantDirectory,'link5_2data1.db'),data)
  end

  def make_link5_data(consumption_data)
    consumption_data.flat_map { |record|
      link_set = get_link_set(record.street_name, record.boundary_street_1, record.boundary_street_2, record.side_code)
      link_set.flat_map { |(linknr,direction)|
        record.consumption_by_min.map_with_index { |consumption,min|
          scale_factor = record.side_code == 'C' ? 0.5 : 1.0
          [linknr,1,1,min+1,1,1,1,direction,0,consumption * scale_factor,record.capacity*scale_factor]
        }
      }
    }

  end

  def get_link_set(street_name, boundary_street_1, boundary_street_2, side_code)
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
end
