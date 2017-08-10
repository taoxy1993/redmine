class CreateVpnAccounts < ActiveRecord::Migration
  def self.up
    create_table :vpn_accounts do |t|
      t.column :cert_name, :string, :limit => 200, :null => false
      t.column :owner_id, :integer, :null => false
      t.column :created_on, :datetime, :null => false
      t.column :expire_time, :datetime, :null => false
      t.column :valid_days, :integer, :null => false
      t.column :key_file_content, :text
      t.column :crt_file_content, :text
      t.column :status, "ENUM('issued', 'abandoned')", :default => 'issued', :null => false
      t.column :resumed, "ENUM('Y', 'N')", :default => 'N', :null => false
    end
  end

  def self.down
    drop_table :vpn_accounts
  end
end
