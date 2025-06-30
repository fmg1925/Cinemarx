# frozen_string_literal: true

class AddBackdropPathToCachedMovies < ActiveRecord::Migration[8.0]
  def change
    add_column :cached_movies, :backdrop_path, :string
  end
end
