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

  def update
    if params[:user].present?
      params[:user].delete_if { |param_name, param_value| (param_name.to_s == "password" || param_name.to_s == "password_confirmation") && param_value.blank?  }
      if current_user.update_attributes(
          :nickname => params[:user][:nickname],
          :email => params[:user][:email],
          :password_confirmation => params[:user][:password_confirmation],
          :password => params[:user][:password]
        )
        sign_in(current_user, :bypass => true)
        flash.notice = "Your profile has been updated"
      end
    else
      flash.alert = "No user data to save"
    end
    render "pages/profile"
  end
end