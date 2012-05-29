class GameController < ApplicationController
  respond_to :html, :mobile

  def index
    @notifications = current_user.notifications.latest_10
  end
end