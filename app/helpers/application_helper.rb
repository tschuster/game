module ApplicationHelper
  def ll(date, options = {})
    return if date.blank?
    l(date, options)
  end

  def log(object)
    Rails.logger.info("="*60)
    Rails.logger.info("Type: #{object.class}")
    Rails.logger.info(object.to_yaml)
    Rails.logger.info("="*60)
  end

  def humanize(secs)
    return "0 seconds" if secs <= 0
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end

  def short_time(secs)
    (Time.mktime(0)+secs).strftime("%H:%M:%S")
  end

  def active_class(controller, action = nil)
    if action.present?
      ' class="active"'.html_safe if params[:controller] == controller && params[:action] == action
    else
      ' class="active"'.html_safe if params[:controller] == controller
    end
  end

  def progress_class_for(value)
    if value <= 33
      " progress-danger" 
    elsif value <= 66
      " progress-warning"
    else
      " progress-success"
    end
  end

  def color_for(value)
    if value <= 33
      "color: #DD514C;" 
    elsif value <= 66
      "color: #FAA732;"
    else
      "color: #5EB95E;"
    end
  end
end