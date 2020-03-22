class AddActiveToBookmark < ActiveRecord::Migration[5.0]
  def change
    add_column :bookmarks, :active, :boolean, default: true
  end
end
