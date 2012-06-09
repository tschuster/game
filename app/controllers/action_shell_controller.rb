# encoding: utf-8
class ActionShellController < ApplicationController
  before_filter :set_shell_from_session
  after_filter :set_session_from_shell

  def index
    if @current_user.has_incomplete_actions?
      redirect_to game_index_path, :alert => "Failed to start ActionShell due to unfinished action"
    else
      @shell.perform! "init"
    end
  end

  def compute
    if params[:command].to_s.downcase.squish == "exit" && !@shell.remote?
      flash[:notice] = "ActionShell session ended"
      render :js => "$('#results_container').hide();document.location.href = '#{game_index_path}';"
    else
      @shell.perform!(params[:command].to_s.squish, params[:delegate])
      render :layout => false
    end
  end

  protected

    def set_session_from_shell
      session[:action_shell] = {
        :history            => @shell.history,
        :result             => @shell.result,
        :current_dir        => @shell.current_dir,
        :file_system        => @shell.file_system,
        :current_connection => @shell.current_connection,
        :password_retry     => @shell.password_retry,
        :authenticated      => @shell.authenticated,
        :clients            => @shell.clients
      }
    end

    def set_shell_from_session
      if session[:action_shell].present?
        @shell = ActionShell.new(
          :history            => session[:action_shell][:history],
          :current_dir        => session[:action_shell][:current_dir],
          :file_system        => session[:action_shell][:file_system],
          :clients            => session[:action_shell][:clients],
          :current_connection => session[:action_shell][:current_connection],
          :password_retry     => session[:action_shell][:password_retry],
          :authenticated      => session[:action_shell][:authenticated],
          :current_user       => current_user
        )
      else
        @shell = ActionShell.new(:current_user => current_user)
        session[:action_shell] = {}
      end
    end
end