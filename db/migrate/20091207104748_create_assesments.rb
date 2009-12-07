class CreateAssesments < ActiveRecord::Migration
  def self.up
    create_table :assesments do |t|
      t.integer :user_id
      t.string :shape_file_name
      t.string :shape_content_type
      t.string :shape_file_size
      t.string :shape_updated_at
      t.string :state
      t.datetime :delete_at
      t.timestamps
    end
  end

  def self.down
    drop_table :assesments
  end
end
