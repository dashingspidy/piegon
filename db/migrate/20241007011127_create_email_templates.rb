class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string :name
      t.text :body
      t.json :template
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
