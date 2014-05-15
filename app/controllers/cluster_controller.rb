class ClusterController < ApplicationController
  before_filter :set_controlled_cluster, only: [:index]
  before_filter :set_cluster, only: [:show]

  respond_to :html, :mobile
  respond_to :json, only: [:show]

  def index
    redirect_to(game_index_path, notice: "You have accepted a job!") unless current_user.admin?
  end

  def show
  end

  protected

    def set_controlled_cluster
      @controlled_cluster = Cluster.where("user_id is not null").pluck(:map_id).map { |c| '"' << c << '"'}.join(",").html_safe
    end

    def set_cluster
      @cluster = Cluster.where(map_id: params[:id]).first
    end
end