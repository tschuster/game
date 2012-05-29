# encoding: utf-8
class ActionShellController < ApplicationController
  before_filter :set_history

  @version = "0.1"

  def index
    @command = "init"
    perform!
    set_session
  end

  def compute
    
    @command = params[:command].to_s.squish
    perform!

    @history << @command
    set_session
    render :index
  end

  protected
    def perform!
      if @command != "init"
        case @command
        when "version"
          @result = "ActionShell v#{@version}"  
        when "help"
          @result = "=br=ActionShell supports the following commands:=br==br=" <<
          "help:      displays this help text=br=" <<
          "ls:        list contents of current folder=br=" <<
          "cd &lt;name&gt;: change directory to &lt;name&gt;"
        when ""
          @result = nil
        else
          @result = "unrecognized command '#{@command}'"
        end
      else
        init!
      end
    end

    def init!
      @history = ["#rInitializing ActionShell v#{@version}...=br==br=Type 'help' for help=br="]
      @result = nil
    end

    def set_history
      @history = if session[:action_shell].present? && session[:action_shell][:history].present?
        session[:action_shell][:history].compact
      else
        []
      end
    end

    def set_session
      if @result.present?
        @history = (@history << "#r#{@result}").compact
      end
      session[:action_shell] = { :history => @history, :result => @result }
    end
end