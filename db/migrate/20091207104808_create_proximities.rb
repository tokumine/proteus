class CreateProximities < ActiveRecord::Migration
  def self.up
    create_table :proximities do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :proximities
  end
end
