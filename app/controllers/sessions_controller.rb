class SessionsController < ApplicationController
  def create
    user = User.find_by(username: params[:user][:username])
    if user&.authenticate(params[:user][:password])
      if !user.enabled?
        flash.now[:alert] = t("login.disabled")
        return render :new, status: :forbidden
      end
      session[:user_id] = user.id
      redirect_to root_path, notice: t("login.success")
    else
      flash.now[:alert] = t("login.error")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: t("login.loggedout")
  end
end
