module JobsHelper
  def job_image_tag(job)
    source = case job.type_id
      when Job::JOB_TYPE_DDOS
        "ddos_attack"
      when Job::JOB_TYPE_SPAM
        "spam"
      when Job::JOB_TYPE_DEFACEMENT
        "defacement"
    end
    image_tag("#{source}.png", :'no_pix' => true)
  end

  def job_requirement(job)
    result = ""
    if job.hacking_ratio_required > 0
      if current_user.hacking_ratio < job.hacking_ratio_required
        result << "<span style='color: #DD514C;'>Hacking skill: #{job.hacking_ratio_required}</span><br />"
      else
        result << "Hacking skill: #{job.hacking_ratio_required}<br />"
      end
    end
    if job.botnet_ratio_required > 0
      if current_user.botnet_ratio < job.botnet_ratio_required
        result << "<span style='color: #DD514C;'>Botnet strength: #{job.botnet_ratio_required}</span>"
      else
        result << "Botnet strength: #{job.botnet_ratio_required}"
      end
    end
    result.html_safe
  end

  def job_requirement_mobile(job)
    result = ""
    if job.hacking_ratio_required > 0
      if current_user.hacking_ratio < job.hacking_ratio_required
        result << "<span style='color: #DD514C;'>Hacking: #{job.hacking_ratio_required}</span><br />"
      else
        result << "Hacking: #{job.hacking_ratio_required}<br />"
      end
    end
    if job.botnet_ratio_required > 0
      if current_user.botnet_ratio < job.botnet_ratio_required
        result << "<span style='color: #DD514C;'>Botnet: #{job.botnet_ratio_required}</span>"
      else
        result << "Botnet: #{job.botnet_ratio_required}"
      end
    end
    result.html_safe
  end

  def accept_button(job)
    result = ""
    if current_user.hacking_ratio < job.hacking_ratio_required || current_user.botnet_ratio < job.botnet_ratio_required
      result << "<span class='btn btn-default disabled'>You are too weak</span>"
    elsif current_user.has_incomplete_actions?
      result << "<span class='btn btn-default disabled'>Action pending</span>"
    else
      result << link_to("accept", accept_job_path(job.id), class: "btn btn-primary")
    end
    result.html_safe
  end

  def accept_button_mobile(job)
    result = ""
    if current_user.hacking_ratio < job.hacking_ratio_required || current_user.botnet_ratio < job.botnet_ratio_required
      result << "<span class='btn btn-default disabled' style='font-size: 9px;'>Too weak</span>"
    elsif current_user.has_incomplete_actions?
      result << "<span class='btn btn-default disabled' style='font-size: 9px;'>Action pending</span>"
    else
      result << link_to("accept", accept_job_path(job.id), class: "btn btn-primary", style: "font-size: 9px;")
    end
    result.html_safe
  end

  def image_for(job)
    if current_user.has_incomplete_actions? || current_user.hacking_ratio < job.hacking_ratio_required || current_user.botnet_ratio < job.botnet_ratio_required
      job_image_tag(job)
    else
      link_to(job_image_tag(job), accept_job_path(job.id))
    end
  end
end