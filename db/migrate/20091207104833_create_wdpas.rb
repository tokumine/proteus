class CreateWdpas < ActiveRecord::Migration
  def self.up
    create_table :wdpas do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :wdpas
  end
end
