# frozen_string_literal: true

# lib/tasks/stress_test.rake
namespace :db do
  desc 'Simula carga a la base de datos'
  task stress: :environment do
    require 'parallel'
    require 'benchmark'
    require 'faker'

    puts 'Iniciando prueba de estrés...'

    elapsed = Benchmark.realtime do
      Parallel.each(1..1000, in_threads: 10) do |_i|
        pass = Faker::Internet.password(min_length: 8)
        User.create!(
          username: "user_#{SecureRandom.hex(4)}",
          password: pass,
          password_confirmation: pass
        )
      rescue ActiveRecord::RecordInvalid => e
        puts "Error al crear usuario: #{e.message}"
        retry
      end
    end
    puts "Prueba completada en #{elapsed.round(2)} segundos."
  end
end
