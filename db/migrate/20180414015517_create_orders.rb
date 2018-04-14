class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :order_id
      t.datetime :uploaded_at
      t.datetime :fulfilled_at
      t.string :items, array: true, default: []

      t.timestamps
    end
  end
end
