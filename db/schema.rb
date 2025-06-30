# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 20_250_630_153_345) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'cached_movies', force: :cascade do |t|
    t.integer 'movie_id'
    t.string 'title'
    t.text 'overview'
    t.string 'poster_path'
    t.string 'language'
    t.float 'vote_average'
    t.integer 'vote_count'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'backdrop_path'
    t.index ['language'], name: 'index_cached_movies_on_language'
    t.index %w[movie_id language], name: 'index_cached_movies_on_movie_id_and_language', unique: true
    t.index ['movie_id'], name: 'index_cached_movies_on_movie_id'
  end

  create_table 'comments', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'movie_id', null: false
    t.integer 'user_id', null: false
    t.string 'content', null: false
  end

  create_table 'favorite_movies', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.integer 'movie_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_favorite_movies_on_user_id'
  end

  create_table 'ratings', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.integer 'movie_id'
    t.integer 'score'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[user_id movie_id], name: 'index_ratings_on_user_id_and_movie_id', unique: true
    t.index ['user_id'], name: 'index_ratings_on_user_id'
  end

  create_table 'sessions', force: :cascade do |t|
    t.string 'session_id', null: false
    t.text 'data'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['session_id'], name: 'index_sessions_on_session_id', unique: true
    t.index ['updated_at'], name: 'index_sessions_on_updated_at'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'username'
    t.string 'password_digest'
    t.boolean 'admin'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.boolean 'enabled', default: true, null: false
  end

  create_table 'watched_movies', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.integer 'movie_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_watched_movies_on_user_id'
  end

  add_foreign_key 'favorite_movies', 'users'
  add_foreign_key 'ratings', 'users'
  add_foreign_key 'watched_movies', 'users'
end
