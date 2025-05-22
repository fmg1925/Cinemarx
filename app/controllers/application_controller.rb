class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :enabled?, :admin?

  before_action :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def enabled?
    current_user&.enabled?
  end

  def admin?
    current_user&.admin?
  end

  def require_login
    redirect_to login_path unless logged_in?
  end

  def require_admin
    redirect_to login_path, alert: t("errors.not_authorized") unless admin?
  end
end
