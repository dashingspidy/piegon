class CreateReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :replies do |t|
      t.text :description
      t.belongs_to :ticket, null: false, foreign_key: true

      t.timestamps
    end
  end
end
