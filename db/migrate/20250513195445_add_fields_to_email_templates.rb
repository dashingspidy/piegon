class AddFieldsToEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    remove_column :email_templates, :template
    add_column :email_templates, :html, :text
    add_column :email_templates, :css, :text
  end
end
