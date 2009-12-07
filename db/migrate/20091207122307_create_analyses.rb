class CreateAnalyses < ActiveRecord::Migration
  def self.up
    create_table :analyses do |t|
      t.string :type
      t.multi_polygon :the_geom, :srid => 4326, :with_z => false
      t.string :name
      t.float :value
      t.string :attribute_data
      t.integer :tenement_id
      t.integer :pa_id
      t.timestamps
    end
  end

  def self.down
    drop_table :analyses
  end
end
