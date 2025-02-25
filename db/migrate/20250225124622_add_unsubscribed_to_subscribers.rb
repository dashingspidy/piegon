class AddUnsubscribedToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :unsubscribed, :boolean, default: false
  end
end
