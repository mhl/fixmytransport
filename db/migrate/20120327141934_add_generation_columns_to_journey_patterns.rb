class AddGenerationColumnsToJourneyPatterns < ActiveRecord::Migration
  def self.up
    add_column :journey_patterns, :generation_low, :integer
    add_column :journey_patterns, :generation_high, :integer
    add_column :journey_patterns, :previous_id, :integer
    add_index :journey_patterns, [:route_id, :generation_low, :generation_high]
  end

  def self.down
    remove_column :journey_patterns, :generation_low
    remove_column :journey_patterns, :generation_high
    remove_column :journey_patterns, :previous_id
  end
end
