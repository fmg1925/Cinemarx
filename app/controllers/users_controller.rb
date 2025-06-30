# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_admin, only: %i[index destroy edit update]
  def index
    query = params[:query]
    users_scope = User.all
    users_scope = users_scope.where('username ILIKE :q', q: "%#{query}%") if query.present?

    @users = users_scope.page(params[:page]).per(10)
    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    current_language_code
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      if admin?
        redirect_to users_path, notice: t('users.created')
      else
        session[:user_id] = @user.id
        redirect_to root_path, notice: t('users.created')
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
    I18n.locale = params[:locale] || extract_locale_from_referer || :en
    current_language_code
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to users_path, notice: t('users.edited')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path, notice: t('users.deleted')
  end

  private

  def user_params
    permitted = %i[username admin enabled]
    permitted << :password << :password_confirmation if params[:user][:password].present?
    params.require(:user).permit(permitted)
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
