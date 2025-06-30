# frozen_string_literal: true

class AddUniqueIndexToCachedMovies < ActiveRecord::Migration[8.0]
  def change
    add_index :cached_movies, %i[movie_id language], unique: true
  end
end
