class Job < ActiveRecord::Base
  belongs_to :user
  has_one :action

  class ImplementationMissingException < StandardError
  end

  JOB_TYPE_DDOS  = 1
  JOB_TYPE_SPAM  = 2
  JOB_TYPE_VIRUS = 3

  scope :incomplete, :conditions => { :completed => false }

  scope :unaccepted, where(:user_id => nil)

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

  def accept_by(user)
    return if completed

    update_attribute(:user_id, user.id)
    action = Action.new(:type_id => Action::TYPE_PERFORM_JOB, :user_id => user.id, :job_id => id)
    Action.add_for_user(action, user)
  end

  def perform!
    user.receive_money!(reward)
    update_attributes(:completed => true, :success => true, :completed_at => DateTime.now)
  end

  class << self
    def generate!
      targets = [
        { :name => "IBM", :ratio => 2500 },
        { :name => "Apple", :ratio => 4000 },
        { :name => "Microsoft", :ratio => 3800 },
        { :name => "Sony", :ratio => 600 }
      ]

      jobs = [ 
        { :type => Job::JOB_TYPE_DDOS, :title => "dDoS Attack", :description => "The client wants you to take out the servers of %{company}." },
        { :type => Job::JOB_TYPE_SPAM, :title => "Spam delivery", :description => "The client wants you to deliver spam mails." },
        { :type => Job::JOB_TYPE_VIRUS, :title => "Virus Development", :description => "The client wants you to develop a virus." }
      ]

      job         = jobs.sample
      description = nil
      difficulty  = nil
      reward      = nil

      if job[:type] == Job::JOB_TYPE_SPAM
        difficulty  = 100 + rand(100)
        reward      = difficulty
        description = job[:description]

      elsif job[:type] == Job::JOB_TYPE_DDOS
        target      = targets.sample
        difficulty  = target[:ratio]
        reward      = target[:ratio]/10
        description = job[:description].gsub("%{company}", target[:name])

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
        :reward => reward
      )
      new_job
    end
  end
end