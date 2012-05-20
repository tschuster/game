module JobsHelper
  def job_image_tag(job)
    source = case job.type_id
      when Job::JOB_TYPE_DDOS
        "ddos_attack"
      when Job::JOB_TYPE_SPAM
        "spam"
      when Job::JOB_TYPE_VIRUS
        "virus"
    end
    image_tag("#{source}.png", :'no_pix' => true)
  end
end