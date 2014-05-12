class JobsController < ApplicationController
  before_filter :set_jobs, only: :index
  before_filter :set_job, only: :accept

  respond_to :html, :mobile

  def index
  end

  def accept
    if @job.user.present? || @job.completed
      flash.alert = "This job cannot be accepted"
    else
      @job.accept_by(current_user)
    end
    redirect_to game_index_path, notice: "You have accepted a job!"
  end

  protected
    def set_jobs
      @simple_jobs = Job.acceptable.simple
      @complex_jobs = Job.acceptable.complex
      @challenging_jobs = Job.acceptable.challenging
    end

    def set_job
      @job = Job.incomplete.find(params[:id])
    end
end