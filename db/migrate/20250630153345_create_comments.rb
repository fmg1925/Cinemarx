# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.timestamps
      t.integer :movie_id, null: false
      t.integer :user_id, null: false
      t.string :content, null: false
    end
  end
end
