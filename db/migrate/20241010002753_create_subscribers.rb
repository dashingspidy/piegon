class CreateSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.references :contact, null: false, foreign_key: true
      t.timestamps
    end
  end
end
