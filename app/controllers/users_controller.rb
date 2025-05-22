class UsersController < ApplicationController
  before_action :require_admin, only: [ :index, :destroy ]
  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: t("users.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to users_path, notice: t("users.edited")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path, notice: t("users.deleted")
  end

  private

  def user_params
    permitted = [ :username, :admin, :enabled ]
    permitted << :password << :password_confirmation if params[:user][:password].present?
    params.require(:user).permit(permitted)
  end
end
