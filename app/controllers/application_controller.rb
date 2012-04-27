class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource
  before_filter :authenticate_user!
  before_filter :set_current_action
  before_filter :set_recent_actions

  def log(object)
    Rails.logger.info("="*60)
    Rails.logger.info("Type: #{object.class}")
    Rails.logger.info(object.to_yaml)
    Rails.logger.info("="*60)
  end

  protected

    def layout_by_resource
      if devise_controller?
        nil
      else
        "application"
      end
    end

    def set_current_action
      @current_action = Action.current_for_user(current_user).first if current_user
      log request.env["HTTP_USER_AGENT"]
    end

    def set_recent_actions
      @recent_actions = Action.where({:completed => true, :user_id => current_user.id}).order("completed_at DESC").limit(5) if current_user
    end
end