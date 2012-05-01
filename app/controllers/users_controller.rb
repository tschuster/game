class UsersController < ApplicationController
  before_filter :authenticate_admin!, :only => :index

  def show
    render :layout => false
  end

  def index
    @users = User.all
  end
end