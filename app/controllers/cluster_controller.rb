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
      @country_color_values = []
      Cluster.all.each do |c|
        if c.user_id == current_user.id
          @country_color_values << "\"#{c.map_id}\":\"#02873a\""
        elsif c.user_id.blank?
          @country_color_values << "\"#{c.map_id}\":\"#c7c7c7\""
        else
          @country_color_values << "\"#{c.map_id}\":\"#8b0101\""
        end
      end
    end

    def set_cluster
      @cluster = Cluster.where(map_id: params[:id]).first
    end
end