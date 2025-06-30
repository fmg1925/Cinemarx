# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :require_login, only: %i[create destroy edit update]

  def index
    @comments = Comment.all
  end

  def create
    return if params[:comment].blank? || params[:comment][:content].blank?

    if Comment.where(user_id: current_user.id, movie_id: params[:comment][:movie_id]).exists?
      flash[:alert] = t('comments.already_commented')
      redirect_to request.referer || movies_path
      return
    end
    @comment = Comment.new(comment_params)
    if @comment.save
      redirect_to request.referer || movies_path, notice: t('comments.created_success')
    else
      Rails.logger.error "Error al crear el comentario: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if (@comment.user == current_user) || current_user.admin?
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to request.referer || movies_path, notice: t('comments.deleted_success') }
        format.js # renderiza destroy.js.erb
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referer || movies_path, alert: t('comments.no_permission') }
        format.js { head :forbidden }
      end
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    if @comment.user == current_user
      render :edit
    else
      redirect_to comments_path, alert: t('comments.no_permission')
    end
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.user == current_user
      if @comment.update(comment_params)
        redirect_to request.referer || movies_path, notice: t('comments.updated_success')
      else
        flash[:alert] = @comment.errors.full_messages.to_sentence
        redirect_to request.referer || movies_path
      end
    else
      redirect_to movies_path, alert: t('comments.no_permission')
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content, :movie_id).merge(user_id: current_user.id)
  end
end
