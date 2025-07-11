# frozen_string_literal: true

class HomeController < ApplicationController
  API_KEY = ENV['API_KEY']
  AUTH_TOKEN = ENV['TOKEN']
  def index
    return unless logged_in?

    favorites_page = params[:favorites_page] || 1
    rated_page     = params[:rated_page]     || 1
    watched_page   = params[:watched_page]   || 1

    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    language = current_language_code

    favorites = current_user.favorite_movies.order(created_at: :desc)
    user_ratings = current_user.ratings.order(created_at: :desc)
    watched = current_user.watched_movies.order(created_at: :desc)

    @comments = current_user.comments.order(created_at: :desc)

    @cached_movies = CachedMovie.where(movie_id: @comments.map(&:movie_id), language: language).index_by(&:movie_id)

    favorite_ids = favorites.pluck(:movie_id)
    rating_ids = user_ratings.pluck(:movie_id)

    favoritemovies = favorites.map do |favoritemovie|
      cached = CachedMovie.find_by(movie_id: favoritemovie.movie_id, language: language)
      next unless cached

      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = begin
        cached.vote_count.to_i
      rescue StandardError
        0
      end

      user_avg = Rating.where(movie_id: favoritemovie.movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: favoritemovie.movie_id).count
      rating = Rating.find_by(user_id: current_user.id, movie_id: favoritemovie.movie_id)
      total_votes = tmdb_votes + user_count

      combined = total_votes.positive? ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5
      {
        'id' => favoritemovie.movie_id,
        'title' => cached.title,
        'overview' => cached.overview,
        'poster_path' => cached.poster_path,
        'backdrop_path' => cached.backdrop_path,
        'user_score' => rating&.score || nil,
        'vote_average' => cached.vote_average.to_f,
        'vote_count' => tmdb_votes,
        'rating' => combined.round(2),
        'total_votes' => total_votes
      }
    end.compact

    all_rated = user_ratings.reject { |rating| favorite_ids.include?(rating.movie_id) }.map do |rating|
      movie_id = rating.movie_id

      cached = CachedMovie.find_by(movie_id: movie_id, language: language)
      next unless cached

      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = begin
        cached.vote_count.to_i
      rescue StandardError
        0
      end

      user_avg = Rating.where(movie_id: movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: movie_id).count
      total_votes = tmdb_votes + user_count

      combined = total_votes.positive? ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5

      {
        'id' => movie_id,
        'title' => cached.title,
        'overview' => cached.overview,
        'poster_path' => cached.poster_path,
        'backdrop_path' => cached.backdrop_path,
        'user_score' => rating.score,
        'vote_average' => cached.vote_average.to_f,
        'vote_count' => tmdb_votes,
        'rating' => combined.round(2),
        'total_votes' => total_votes
      }
    end.compact

    watchedmovies = watched.reject { |watchedmovie| rating_ids.include?(watchedmovie.movie_id) }.map do |watchedmovie|
      cached = CachedMovie.find_by(movie_id: watchedmovie.movie_id, language: language)
      next unless cached

      tmdb_rating_5 = cached.vote_average.to_f / 2.0
      tmdb_votes = begin
        cached.vote_count.to_i
      rescue StandardError
        0
      end

      user_avg = Rating.where(movie_id: watchedmovie.movie_id).average(:score) || 0
      user_count = Rating.where(movie_id: watchedmovie.movie_id).count
      total_votes = tmdb_votes + user_count

      combined = total_votes.positive? ? ((tmdb_rating_5 * tmdb_votes + user_avg * user_count) / total_votes) : tmdb_rating_5

      {
        'id' => watchedmovie.movie_id,
        'title' => cached.title,
        'overview' => cached.overview,
        'poster_path' => cached.poster_path,
        'backdrop_path' => cached.backdrop_path,
        'vote_average' => cached.vote_average.to_f,
        'vote_count' => tmdb_votes,
        'rating' => combined.round(2),
        'total_votes' => total_votes
      }
    end.compact

    @favorite_movies = Kaminari.paginate_array(favoritemovies).page(favorites_page).per(10)
    @rated_movies = Kaminari.paginate_array(all_rated).page(rated_page).per(10)
    @watched_movies = Kaminari.paginate_array(watchedmovies).page(watched_page).per(10)

    @movies = []

    if @favorite_movies.empty? && @rated_movies.empty? && @watched_movies.empty?
      language = current_language_code

      api_url = "https://api.themoviedb.org/3/movie/popular?api_key=#{API_KEY}&language=#{language}&page=1"
      response = HTTParty.get(api_url, headers: { 'Authorization' => "Bearer #{AUTH_TOKEN}" })

      if response.success?
        rawmovies = response.parsed_response['results']

        rawmovies.each do |movie|
          tmdb_rating_5 = movie['vote_average'].to_f / 2.0
          tmdb_votes = begin
            movie['vote_count'].to_i
          rescue StandardError
            0
          end

          user_ratings = Rating.where(movie_id: movie['id'])
          user_avg = user_ratings.average(:score) || 0
          user_count = user_ratings.count

          total_votes = tmdb_votes + user_count

          combined = if total_votes.positive?
                       ((tmdb_rating_5 * tmdb_votes) + (user_avg * user_count)) / total_votes
                     else
                       tmdb_rating_5
                     end

          movie['rating'] = combined.round(2)
          movie['total_votes'] = total_votes
        end
        @movies = rawmovies
      end
    else
      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('favorite_movies', partial: 'home/favorite_movies',
                                                    locals: { favorite_movies: @favorite_movies }),
            turbo_stream.replace('rated_movies', partial: 'home/rated_movies', locals: { rated_movies: @rated_movies }),
            turbo_stream.replace('watched_movies', partial: 'home/watched_movies',
                                                   locals: { watched_movies: @watched_movies })
          ]
        end
      end
    end
  end

  def extract_locale_from_referer
    URI.parse(request.referer || '').query
       &.split('&')
       &.map { |p| p.split('=') }
       &.to_h&.[]('locale')
       &.to_sym
  rescue StandardError
    nil
  end

  private

  def current_language_code
    case I18n.locale
    when :es then 'es-MX'
    when :en then 'en-US'
    when :ko then 'ko-KR'
    when :zh then 'zh-CN'
    else 'en-US'
    end
  end
end
