class CreateAssesments < ActiveRecord::Migration
  def self.up
    create_table :assesments do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :assesments
  end
end
