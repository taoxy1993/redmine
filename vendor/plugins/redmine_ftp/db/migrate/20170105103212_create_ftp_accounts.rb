class CreateFtpAccounts < ActiveRecord::Migration
  def self.up
    create_table :ftp_accounts do |t|
      t.column :name, :string, :limit => 30, :null => false
      t.column :password, :string, :limit => 40, :null => false
      t.column :expire_time, :datetime, :null => false
      t.column :creator_id, :integer, :null => false
      t.column :email, :string, :limit => 60, :null => false
      t.column :created_on, :datetime, :null => false
      t.column :obsoleted_on, :datetime
      t.column :status, :integer, :default => 1, :null => false
    end
  end

  def self.down
    drop_table :ftp_accounts
  end
end
