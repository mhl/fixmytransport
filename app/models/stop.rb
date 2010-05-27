# == Schema Information
# Schema version: 20100506162135
#
# Table name: stops
#
#  id                         :integer         not null, primary key
#  atco_code                  :string(255)
#  naptan_code                :string(255)
#  plate_code                 :string(255)
#  common_name                :text
#  short_common_name          :text
#  landmark                   :text
#  street                     :text
#  crossing                   :text
#  indicator                  :text
#  bearing                    :string(255)
#  nptg_locality_code         :string(255)
#  locality_name              :string(255)
#  parent_locality_name       :string(255)
#  grand_parent_locality_name :string(255)
#  town                       :string(255)
#  suburb                     :string(255)
#  locality_centre            :boolean
#  grid_type                  :string(255)
#  easting                    :float
#  northing                   :float
#  lon                        :float
#  lat                        :float
#  stop_type                  :string(255)
#  bus_stop_type              :string(255)
#  administrative_area_code   :string(255)
#  creation_datetime          :datetime
#  modification_datetime      :datetime
#  revision_number            :integer
#  modification               :string(255)
#  status                     :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  coords                     :geometry
#


class Stop < ActiveRecord::Base
  named_scope :active, :conditions => { :status => 'act' }
  has_many :stop_area_memberships
  has_many :stop_areas, :through => :stop_area_memberships
  validates_presence_of :common_name
  has_many :problems, :as => :location
  has_many :route_segments_as_from_stop, :foreign_key => 'from_stop_id', :class_name => 'RouteSegment'
  has_many :route_segments_as_to_stop, :foreign_key => 'to_stop_id', :class_name => 'RouteSegment'
  has_many :routes_as_from_stop, :through => :route_segments_as_from_stop, :source => 'route'
  has_many :routes_as_to_stop, :through => :route_segments_as_to_stop, :source => 'route'
  belongs_to :locality
  
  def routes
    (routes_as_from_stop | routes_as_to_stop).uniq.sort{ |a,b| a.name <=> b.name }
  end
  
  def name
    common_name
  end
  
  def description
    "#{name} #{area}"
  end
  
  def full_name
    descriptors = [name]
    [street, indicator, landmark, crossing].each do |attribute|
      descriptors << attribute if !attribute.blank? and ! descriptors.include? attribute
    end
    text = descriptors.join(" ")
    text += " (#{bearing})" if ! bearing.blank?
    text
  end
  
  def area
    locality_name
  end
  
  def name_without_station
    text = name.gsub(' Rail Station', '')
    text
  end
  
  def name_without_metro_station
    text = name.gsub(' Underground Station', '')
    text
  end
  
  def name_and_bearing
    text = "#{name}"
    text += " (#{bearing})" if ! bearing.blank?
    text
  end
  
  def self.common_area(stops, transport_mode_id)
    stop_area_type_codes = StopAreaType.codes_for_transport_mode(transport_mode_id)
    stop_area_sets = stops.map{ |stop| stop.stop_areas.select{ |stop_area| stop_area_type_codes.include? stop_area.area_type } }
    stop_areas = stop_area_sets.inject{ |intersection_set,stop_area_set| intersection_set & stop_area_set }
    root_stop_areas = stop_areas.select{ |stop_area| stop_area.root? }
    if root_stop_areas.size == 1
      return root_stop_areas.first
    end
    if stop_areas.size == 1
      return stop_areas.first
    end
    return nil
  end
  
  def self.find_from_attributes(attributes)
    stop_type_codes = StopType.codes_for_transport_mode(attributes[:transport_mode_id])
    area = attributes[:area].downcase
    name = attributes[:name].downcase
    query_clauses = []
    params = []
    if !name.blank? 
      query_clauses << 'lower(common_name) like ?'
      params <<  "%#{name}%"
    end
    if !area.blank?
      query_clauses << '(lower(locality_name) = ? 
       OR lower(parent_locality_name) = ?
       OR lower(grand_parent_locality_name) = ?)'
      3.times{ params << area }
    end
    query_clauses << 'stop_type in (?)'
    params << stop_type_codes
    params.unshift(query_clauses.join(" AND "))
    active.find(:all, :conditions => params)
  end
  
  def self.find_by_name_and_coords(name, easting, northing, distance)
    stops = find_by_sql(["SELECT   *, ABS(easting - ?) as easting_dist, ABS(northing - ?) as northing_dist
                          FROM     stops
                          WHERE    common_name = ? 
                          AND      ABS(easting - ?) < ? 
                          AND      ABS(northing - ?) < ?
                          ORDER BY easting_dist asc, northing_dist asc
                          LIMIT 1",
                          easting, northing, name, easting, distance, northing, distance])
    stops.empty? ? nil : stops.first
  end
  
  def self.find_by_atco_code(atco_code, options={})
    includes = options[:includes] or {}
    find(:first, :conditions => ["lower(atco_code) = ?", atco_code.downcase], :include => includes)
  end
  
  def self.match_old_stop(stop)
     existing = find_by_atco_code(stop.atco_code)
     return existing if existing
     existing = find_by_name_and_coords(stop.common_name, stop.easting, stop.northing, 5)     
     return existing if existing
     existing = find_by_easting_and_northing(stop.easting, stop.northing)
     return existing if existing
     return nil
  end
  
end
