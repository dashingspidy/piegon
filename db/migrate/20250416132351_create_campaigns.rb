class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.string :name
      t.references :contact, null: false, foreign_key: true
      t.references :email_template, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :from
      t.string :header
      t.string :subject
      t.datetime :send_at
      t.boolean :finished, default: false
      t.boolean :running, default: false

      t.timestamps
    end
  end
end
