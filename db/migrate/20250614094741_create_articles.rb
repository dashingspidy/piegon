class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :keywords, null: false
      t.text :meta_description, null: false

      t.timestamps
    end
  end
end
