class CreateCompiles < ActiveRecord::Migration
  def self.up
    create_table :compiles do |t|
      t.column :project_id, :integer
      t.column :produce, :string
      t.column :branches, :string
      t.column :tags, :integer
    end
  end

  def self.down
    drop_table :compiles
  end
end
