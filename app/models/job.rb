class Job < ActiveRecord::Base
  belongs_to :target
  belongs_to :user
  has_one :action

  class ImplementationMissingException < StandardError
  end

  JOB_TYPE_DDOS  = 1
  JOB_TYPE_SPAM  = 2
  JOB_TYPE_VIRUS = 3

  scope :incomplete, :conditions => { :completed => false }

  def duration_for(current_user)
    case type_id
      when Job::JOB_TYPE_SPAM
        (difficulty*6000/current_user.botnet_ratio).to_i
      when Job::JOB_TYPE_DDOS
        (difficulty/current_user.botnet_ratio).to_i*400
      when Job::JOB_TYPE_VIRUS
        (difficulty*6000/current_user.hacking_ratio).to_i
    else
      raise Job::ImplementationMissingException.new("Type-id = #{type_id}")
    end
  end

  def accept_by(current_user)
    update_attribute(:user_id, current_user.id)
    action = Action.new(:type_id => Action::TYPE_PERFORM_JOB, :user_id => current_user.id, :job_id => id)
    Action.add_for_user(action, current_user)
  end

  def perform!
    user.receive_money!(reward)
    update_attributes(:completed => true, :success => true, :completed_at => DateTime.now)
  end

  class << self
    def generate!
      jobs = [ 
        { :type => Job::JOB_TYPE_DDOS, :title => "dDoS Attack", :description => "The client wants you to take out the servers of %{company}." },
        { :type => Job::JOB_TYPE_SPAM, :title => "Spam delivery", :description => "The client wants you to deliver spam mails." },
        { :type => Job::JOB_TYPE_VIRUS, :title => "Virus Development", :description => "The client wants you to develop a virus." }
      ]

      job         = jobs.sample
      description = nil
      difficulty  = nil
      reward      = nil
      target      = nil

      if job[:type] == Job::JOB_TYPE_SPAM
        difficulty  = 100 + rand(100)
        reward      = difficulty
        description = job[:description]

      elsif job[:type] == Job::JOB_TYPE_DDOS
        target      = Target.find(:first, :offset => rand(Target.count))
        difficulty  = target.difficulty
        reward      = target.difficulty/10
        description = job[:description].gsub("%{company}", target.name)

      elsif job[:type] == Job::JOB_TYPE_VIRUS
        difficulty  = 100 + rand(100)
        reward      = difficulty
        description = job[:description]
      else
        raise Job::ImplementationMissingException.new
      end

      new_job = Job.create(
        :title => job[:title],
        :description => description,
        :type_id => job[:type],
        :difficulty => difficulty,
        :reward => reward,
        :target => target
      )
      new_job
    end
  end
end