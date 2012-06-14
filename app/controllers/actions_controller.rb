class ActionsController < ApplicationController
  respond_to :html, :mobile

  def index
  end

  def operations
    @attackable_users = User.where("id != ?", current_user.id).delete_if { |user| current_user.chance_of_success_against(user, :hack) <= 0.0 && current_user.chance_of_success_against(user, :ddos) <= 0.0 }
    @not_attackable_users = User.where("id != ?", current_user.id).where("id NOT IN (?)", @attackable_users.map(&:id))
    @companies = Company.all
  end

  def current
    render :layout => false
  end

  def create
    @action = Action.new(:type_id => params[:type_id].to_i, :user_id => current_user.id, :target_id => params[:target_id])

    if Action.add_for_user(@action, current_user)
      redirect_to game_index_path, notice: 'You are performing an action'
    else
      redirect_to game_index_path, alert: 'Action impossible'
    end
  end

  def destroy
    @action = Action.where(:id => params[:id], :user_id => current_user.id, :completed => false).first
    if @action.present?
      if @action.job.present?
        @action.job.update_attributes(:completed => false, :success => nil, :user_id => nil)
      end
      @action.destroy
      flash.notice = "Action was successfully canceled."
    else
      flash.alert = "No Action to cancel"
    end

    redirect_to game_index_path
  end
end