module NotificationsHelper
  def style_for(notification)
    style = "font-weight: bold; " if notification.is_new
    klass = "alert-info" if notification.klass != :news
    "style='#{style}' class='#{klass}'".html_safe
  end
end