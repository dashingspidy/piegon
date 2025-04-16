class CreateCsvUploaders < ActiveRecord::Migration[8.0]
  def change
    create_table :csv_uploaders do |t|
      t.belongs_to :contact, foreign_key: true

      t.timestamps
    end
  end
end
