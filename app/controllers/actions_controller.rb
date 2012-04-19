class ActionsController < ApplicationController

  def index
  end

  def current
    render :layout => false
  end

  def create
    @action = Action.new(:type_id => params[:type_id].to_i, :user_id => current_user.id)

    if Action.add_for_user(@action, current_user)
      redirect_to game_index_path, notice: 'You are performing an action'
    else
      redirect_to game_index_path, alert: 'Actions awaiting completion'
    end
  end

  def destroy
    @action = Action.where(:id => params[:id], :user_id => current_user.id, :completed => false).first
    if @action.present?
      if @action.job.present?
        @action.job.update_attributes(:completed => true, :success => false)
      end
      @action.destroy
      message = 'Action was successfully canceled.'
    else
      message = "No Action to cancel"
    end

    redirect_to game_index_path, notice: message
  end
end
