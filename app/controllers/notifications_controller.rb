class NotificationsController < ApplicationController
  respond_to :html, :json

  def index
  end

  def read
    current_user.notifications.unread.update_all(:is_new => false)
    redirect_to "http://derschuster.de/game"
  end

  protected
    def set_notifications
      @notifications = current_user.notifications.latest_10
    end
end