class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.string :name, null: false
      t.integer :cost, null: false
      t.boolean :paid
      t.string :line_user_id, null: false

      t.timestamps
      t.index :line_user_id
    end
  end
end
