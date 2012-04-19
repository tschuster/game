class JobsController < ApplicationController
  before_filter :set_jobs, :only => :index
  before_filter :set_job, :only => :accept

  def index
  end

  def accept
    @job.accept_by(current_user)
    flash[:notice] = "You have accepted a job!"
    redirect_to game_index_path
  end

  protected
    def set_jobs
      @jobs = Job.incomplete
    end

    def set_job
      @job = Job.incomplete.find(params[:id])
    end
end
