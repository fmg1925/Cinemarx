# frozen_string_literal: true

class AddEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :enabled, :boolean, default: true, null: false
  end
end
