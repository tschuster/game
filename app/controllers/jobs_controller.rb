class JobsController < ApplicationController
  before_filter :set_jobs, :only => :index
  before_filter :set_job, :only => :accept

  respond_to :html, :mobile

  def index
  end

  def accept
    @job.accept_by(current_user)
    redirect_to game_index_path, :notice => "You have accepted a job!"
  end

  protected
    def set_jobs
      @jobs = Job.incomplete
    end

    def set_job
      @job = Job.incomplete.find(params[:id])
    end
end