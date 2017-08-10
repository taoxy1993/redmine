class AddSvnPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :svnpassword, :string
  end

  def self.down
    remove_column :users, :svnpassword
  end
end
