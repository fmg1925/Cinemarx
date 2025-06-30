# frozen_string_literal: true

class CreateCachedMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :cached_movies do |t|
      t.integer :movie_id
      t.string :title
      t.text :overview
      t.string :poster_path
      t.string :language
      t.float :vote_average
      t.integer :vote_count

      t.timestamps
    end

    add_index :cached_movies, :movie_id
    add_index :cached_movies, :language
  end
end
