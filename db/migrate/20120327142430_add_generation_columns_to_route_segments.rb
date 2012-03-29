class AddGenerationColumnsToRouteSegments < ActiveRecord::Migration
  def self.up
    add_column :route_segments, :generation_low, :integer
    add_column :route_segments, :generation_high, :integer
    add_column :route_segments, :previous_id, :integer

    remove_index :route_segments, :journey_pattern_id
    remove_index :route_segments, :route_id
    remove_index :route_segments, [:route_id, :from_stop_area_id]
    remove_index :route_segments, :from_stop_area_id
    remove_index :route_segments, :from_stop_id
    remove_index :route_segments, [:route_id, :to_stop_area_id]
    remove_index :route_segments, :to_stop_area_id
    remove_index :route_segments, :to_stop_id
    
    add_index :route_segments, [:journey_pattern_id, :generation_low, :generation_high]
    add_index :route_segments, [:route_id, :generation_low, :generation_high]
    add_index :route_segments, [:route_id, :from_stop_area_id, :generation_low, :generation_high]
    add_index :route_segments, [:from_stop_area_id, :generation_low, :generation_high]
    add_index :route_segments, [:from_stop_id, :generation_low, :generation_high]
    add_index :route_segments, [:route_id, :to_stop_area_id, :generation_low, :generation_high]
    add_index :route_segments, [:to_stop_area_id, :generation_low, :generation_high]
    add_index :route_segments, [:to_stop_id, :generation_low, :generation_high]
  end

  def self.down
    remove_column :route_segments, :generation_low
    remove_column :route_segments, :generation_high
    remove_column :route_segments, :previous_id
    
    add_index :route_segments, :journey_pattern_id
    add_index :route_segments, :route_id
    add_index :route_segments, [:route_id, :from_stop_area_id]
    add_index :route_segments, :from_stop_area_id
    add_index :route_segments, :from_stop_id
    add_index :route_segments, [:route_id, :to_stop_area_id]
    add_index :route_segments, :to_stop_area_id
    add_index :route_segments, :to_stop_id
    
  end
end
