class CreatePubliclibs < ActiveRecord::Migration
  def self.up
    create_table :publiclibs do |t|
      t.column :project_id, :integer
      t.column :username, :string
      t.column :releasedate, :string
      t.column :releasenote, :text
      t.column :releaseversion, :string
      t.column :reserved1, :string
      t.column :reserved2, :string
      t.column :reserved3, :string
      t.column :reserved4, :integer
      t.column :reserved5, :integer
    end
  end

  def self.down
    drop_table :publiclibs
  end
end
