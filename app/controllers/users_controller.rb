class UsersController < ApplicationController
  before_filter :authenticate_admin!, only: [:index]
  respond_to :html, :mobile
  respond_to :html, :mobile, :json, only: [:stats]

  def show
    render layout: false
  end

  def index
    @users = User.all
    @users.sort_by!(&:nickname)
    @users_nicknames = @users.map { |u| "'#{u.nickname}'" }
    
    @hacking_strengths = "{name:'Hacking skill', data: [" << @users.map { |u| u.hacking_ratio }.join(",") << "]}"
    @botnet_strengths  = "{name:'Botnet strength', data: [" << @users.map { |u| u.botnet_ratio }.join(",") << "]}"
    @defense_strengths = "{name:'Defense ratio', data: [" << @users.map { |u| u.defense_ratio }.join(",") << "]}"
    @moneys            = "{name:'Money', data: [" << @users.map { |u| u.money }.join(",") << "]}"

    
  end

  def stats
  end

  def update
    if params[:user].present?
      params[:user].delete_if { |param_name, param_value| (param_name.to_s == "password" || param_name.to_s == "password_confirmation") && param_value.blank? }
      if params[:user][:notify].to_i == 1 && params[:user][:email].blank?
        flash.alert = "How am I supposed to notify you without your email address?!"
      else
        if current_user.update_attributes(
            nickname: params[:user][:nickname],
            email: params[:user][:email],
            notify: params[:user][:notify],
            password_confirmation: params[:user][:password_confirmation],
            password: params[:user][:password]
          )
          sign_in(current_user, bypass: true)
          flash.notice = "Your profile has been updated"
        else
          flash.alert = "Could not save user data"
        end
      end
    else
      flash.alert = "No user data to save"
    end
    render "pages/profile"
  end
end