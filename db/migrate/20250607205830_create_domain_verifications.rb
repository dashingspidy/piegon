class CreateDomainVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :domain_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :domain, null: false
      t.string :verification_status, default: 'pending'
      t.string :sendgrid_domain_id
      t.text :dns_records
      t.datetime :verified_at

      t.timestamps
    end

    add_index :domain_verifications, [ :user_id, :domain ], unique: true
    add_index :domain_verifications, :verification_status
  end
end
