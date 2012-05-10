class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource
  before_filter :authenticate_user!
  before_filter :set_current_action
  before_filter :set_recent_actions
  before_filter :force_mobile_format

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
    end

    def set_recent_actions
      @recent_actions = Action.where({:completed => true, :user_id => current_user.id}).order("completed_at DESC").limit(5) if current_user
    end

    def authenticate_admin!
      redirect_to(root_path) if current_user.blank? || !current_user.admin?
    end

    def mobile?
      return if devise_controller?
      mobile_user_agents = 'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                           'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                           'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
                           'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                           'webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|' +
                           'mobile'
      (request.user_agent.to_s.downcase =~ Regexp.new(mobile_user_agents)).present?
    end

    def force_mobile_format
      request.format = :mobile if mobile?
    end

  private

    # Overwriting the sign_out redirect path method
    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    # Overwriting the sign_in redirect path method
    def after_sign_in_path_for(resource)
      game_index_path
    end
end