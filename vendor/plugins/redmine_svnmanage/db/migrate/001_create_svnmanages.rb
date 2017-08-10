class CreateSvnmanages < ActiveRecord::Migration
  def self.up
    create_table :svnmanages do |t|
      t.column :project_id, :integer
      t.column :login, :string
      t.column :svn_trunk, :string
      t.column :permission_path, :string
      t.column :svnpath, :string
      t.column :wrstatus, :string
      t.column :member_id, :integer
      t.column :role_id, :integer
    end
  end

  def self.down
    drop_table :svnmanages
  end
end
