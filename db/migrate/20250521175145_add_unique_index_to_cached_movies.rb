class AddUniqueIndexToCachedMovies < ActiveRecord::Migration[8.0]
  def change
    add_index :cached_movies, [ :movie_id, :language ], unique: true
  end
end
