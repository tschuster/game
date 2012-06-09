class NotificationsController < ApplicationController
  respond_to :html, :json

  def index
  end

  def read
    current_user.notifications.unread.update_all(:is_new => false)
    redirect_to root_path
  end

  protected
    def set_notifications
      @notifications = current_user.notifications.latest_10
    end
end