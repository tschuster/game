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

  def humanize secs
    return "0 seconds" if secs <= 0
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end

  def active_class(controller)
    ' class="active"'.html_safe if params[:controller] == controller
  end
end