class Job < ActiveRecord::Base
  belongs_to :user
  has_one :action

  class ImplementationMissingException < StandardError
  end

  JOB_TYPE_DDOS  = 1
  JOB_TYPE_SPAM  = 2
  JOB_TYPE_DEFACEMENT = 3

  scope :incomplete, :conditions => { :completed => false }
  scope :unaccepted, where(:user_id => nil)
  scope :simple, where(:complexity => 1).order("type_id ASC")
  scope :complex, where(:complexity => 2).order("type_id ASC")
  scope :challenging, where(:complexity => 5).order("type_id ASC")

  def duration_for(current_user)
    case type_id
      when Job::JOB_TYPE_SPAM
        (difficulty*6000/current_user.botnet_ratio).to_i
      when Job::JOB_TYPE_DDOS
        (difficulty*6000/current_user.botnet_ratio).to_i
      when Job::JOB_TYPE_DEFACEMENT
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

    Job.generate!
  end

  def perform!
    user.receive_money!(reward)
    update_attributes(:completed => true, :success => true, :completed_at => DateTime.now)
  end

  class << self

    def acceptable
      incomplete.unaccepted
    end

    def should_generate?
      Job.acceptable.where(:complexity => 1, :type_id => Job::JOB_TYPE_DDOS).count < 1 ||
      Job.acceptable.where(:complexity => 1, :type_id => Job::JOB_TYPE_DEFACEMENT).count < 1 ||
      Job.acceptable.where(:complexity => 2, :type_id => Job::JOB_TYPE_DDOS).count < 1 ||
      Job.acceptable.where(:complexity => 2, :type_id => Job::JOB_TYPE_DEFACEMENT).count < 1 ||
      Job.acceptable.where(:complexity => 5, :type_id => Job::JOB_TYPE_DDOS).count < 1 ||
      Job.acceptable.where(:complexity => 5, :type_id => Job::JOB_TYPE_DEFACEMENT).count < 1
    end

    def generate!
      return unless should_generate?

      [1, 2, 5].each do |cplx|
        (3 - Job.acceptable.where(:complexity => cplx, :type_id => Job::JOB_TYPE_DDOS).count).times do

          difficulty = cplx*100 + rand(cplx*100)
          if cplx == 1
            hacking_ratio_required = 0
            botnet_ratio_required  = 10
          elsif cplx == 2
            hacking_ratio_required = 0
            botnet_ratio_required  = (User.average_botnet_ratio*1.6).to_i
            difficulty = 350 + rand(cplx*100)
          elsif cplx == 5
            hacking_ratio_required = 0
            botnet_ratio_required  = (User.best_botnet_ratio*1.2).to_i
          end

          Job.create(
            :title                  => "dDoS Attack",
            :description            => "The client wants you to take out the servers of a company.",
            :type_id                => Job::JOB_TYPE_DDOS,
            :difficulty             => difficulty,
            :reward                 => difficulty,
            :hacking_ratio_required => hacking_ratio_required,
            :botnet_ratio_required  => botnet_ratio_required,
            :complexity             => cplx
          )
        end

        (3 - Job.acceptable.where(:complexity => cplx, :type_id => Job::JOB_TYPE_DEFACEMENT).count).times do

          if cplx == 1
            hacking_ratio_required = 10
            botnet_ratio_required  = 0
          elsif cplx == 2
            hacking_ratio_required = (User.average_hacking_ratio*0.9).to_i
            botnet_ratio_required  = 0
          elsif cplx == 5
            hacking_ratio_required = (User.best_hacking_ratio*0.9).to_i
            botnet_ratio_required  = 0
          end

          difficulty = cplx*100 + rand(cplx*100)

          Job.create(
            :title                  => "Defacement",
            :description            => "The client wants you to vandalize a website.",
            :type_id                => Job::JOB_TYPE_DEFACEMENT,
            :difficulty             => difficulty,
            :reward                 => difficulty,
            :hacking_ratio_required => hacking_ratio_required,
            :botnet_ratio_required  => botnet_ratio_required,
            :complexity             => cplx
          )
        end
      end
    end
  end
end