class CreateTrunks < ActiveRecord::Migration
  def self.up
    create_table :trunks do |t|
      t.column :project_id, :integer
      t.column :creater, :string
      t.column :repository_name, :string
      t.column :tags, :string
      t.column :branches, :string
      t.column :svn_path_type, :string
      t.column :status, :string, :limit => 30, :default => 'normal', :null => true
    end
  end

  def self.down
    drop_table :trunks
  end
end
