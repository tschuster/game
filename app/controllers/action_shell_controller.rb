# encoding: utf-8
class ActionShellController < ApplicationController
  before_filter :set_shell_from_session
  after_filter :set_session_from_shell

  def index
    @shell.perform! "init"
  end

  def compute
    if params[:command].to_s.downcase.squish == "exit"
      redirect_to game_index_path, :notice => "ActionShell session ended"
    else
      @shell.perform! params[:command].to_s.squish
      render :layout => false
    end
  end

  protected

    def set_session_from_shell
      session[:action_shell] = {
        :history => @shell.history,
        :result => @shell.result,
        :current_dir => @shell.current_dir,
        :file_system => @shell.file_system,
        :clients => @shell.clients
      }
    end

    def set_shell_from_session
      if session[:action_shell].present?
        @shell = ActionShell.new(
          :history      => session[:action_shell][:history],
          :current_dir  => session[:action_shell][:current_dir],
          :file_system  => session[:action_shell][:file_system],
          :clients      => session[:action_shell][:clients],
          :current_user => current_user
        )
      else
        @shell = ActionShell.new(:current_user => current_user)
        session[:action_shell] = {}
      end
    end
end