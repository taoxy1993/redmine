class AddBelonggedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :belonged, :string
    add_column :users, :depantment, :string
  end

  def self.down
    remove_column :users, :depantment
    remove_column :users, :belonged
  end
end
