class AddContainsPosterToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :contains_poster, :boolean
  end
end
