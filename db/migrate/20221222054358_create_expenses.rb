class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.string :name
      t.integer :cost
      t.boolean :paid
      t.string :line_user_id

      t.timestamps
    end
  end
end
