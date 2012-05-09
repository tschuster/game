module NotificationsHelper
  def style_for(notification)
    style = "font-weight: bold; " if notification.is_new
    klass = "alert-info" if notification.user == current_user
    "style='#{style}' class='#{klass}'"
  end
end