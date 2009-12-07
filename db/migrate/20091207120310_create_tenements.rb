class CreateTenements < ActiveRecord::Migration
  def self.up
    create_table :tenements do |t|
      t.integer :assesment_id
      t.multi_polygon :the_geom, :srid => 4326, :with_z => false
      t.text :attribute_data
      t.timestamps
    end
  end

  def self.down
    drop_table :tenements
  end
end
