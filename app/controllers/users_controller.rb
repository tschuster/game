class UsersController < ApplicationController
  before_filter :authenticate_admin!, :only => :index
  respond_to :html, :mobile

  def show
    render :layout => false
  end

  def index
    @users = User.all
  end

  def stats
  end
end