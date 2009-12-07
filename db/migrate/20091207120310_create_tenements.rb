class CreateTenements < ActiveRecord::Migration
  def self.up
    create_table :tenements do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :tenements
  end
end
