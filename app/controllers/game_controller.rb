class GameController < ApplicationController

  def index
    @notifications = current_user.notifications.latest_10
  end
end