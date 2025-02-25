class CreateMailSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :mail_settings do |t|
      t.string :host
      t.string :username
      t.string :password
      t.string :port, default: '587'
      t.belongs_to :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
