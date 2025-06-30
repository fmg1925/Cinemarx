# frozen_string_literal: true

class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :movie_id
      t.integer :score

      t.timestamps
    end
  end
end
