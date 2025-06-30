# frozen_string_literal: true

class AddUniqueIndexToRatings < ActiveRecord::Migration[8.0]
  def change
    add_index :ratings, %i[user_id movie_id], unique: true
  end
end
