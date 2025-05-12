class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :subject
      t.text :description
      t.boolean :finished, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
