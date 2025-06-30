# frozen_string_literal: true

# lib/tasks/stress_test.rake
namespace :db do
  desc 'Simula carga en todas las tablas'
  task full_stress: :environment do
    require 'faker'
    require 'securerandom'
    require 'benchmark'
    require 'parallel'

    puts 'Iniciando stress test completo...'

    elapsed = Benchmark.realtime do
      Parallel.each(1..10_000, in_threads: 10) do |_i|
        ActiveRecord::Base.connection_pool.with_connection do
          pass = Faker::Internet.password(min_length: 8)
          user = User.create!(
            username: "user_#{SecureRandom.hex(4)}",
            password: pass,
            password_confirmation: pass,
            admin: [true, false].sample,
            enabled: true
          )

          # Insertar películas (solo si no existen)
          5.times do
            movie_id = rand(1..10_000)
            lang = %w[en es fr de].sample
            begin
              CachedMovie.create!(
                movie_id: movie_id,
                title: Faker::Movie.title,
                overview: Faker::Lorem.paragraph,
                poster_path: "/images/#{SecureRandom.hex(2)}.jpg",
                language: lang,
                vote_average: rand * 10,
                vote_count: rand(1..10_000)
              )
            rescue StandardError
              nil
            end
          end

          # Películas favoritas
          2.times do
            FavoriteMovie.create!(
              user_id: user.id,
              movie_id: rand(1..10_000)
            )
          rescue StandardError
            nil
          end

          # Calificaciones
          3.times do
            Rating.create!(
              user_id: user.id,
              movie_id: rand(1..10_000),
              score: rand(1..10)
            )
          rescue StandardError
            nil
          end

          # Películas vistas
          4.times do
            WatchedMovie.create!(
              user_id: user.id,
              movie_id: rand(1..10_000)
            )
          rescue StandardError
            nil
          end

          # Sesión
          begin
            Session.create!(
              session_id: SecureRandom.uuid,
              data: { user_id: user.id }.to_json
            )
          rescue StandardError
            nil
          end
        rescue StandardError => e
          puts "Error: #{e.class} - #{e.message}"
        end
      end
    end

    puts "Stress test completado en #{elapsed.round(2)} segundos."
  end
end
