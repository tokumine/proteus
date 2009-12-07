class CreateOverlaps < ActiveRecord::Migration
  def self.up
    create_table :overlaps do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :overlaps
  end
end
