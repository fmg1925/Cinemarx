class CreateWatchedMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :watched_movies do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :movie_id

      t.timestamps
    end
  end
end
