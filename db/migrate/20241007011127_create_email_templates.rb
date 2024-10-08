class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.json :template, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
