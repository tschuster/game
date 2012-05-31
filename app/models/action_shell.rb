# encoding: utf-8
class ActionShell

  def initialize(options={})
    @history      = Array.wrap(options[:history])
    @current_dir  = options[:current_dir]
    @file_system  = options[:file_system]
    @current_user = options[:current_user]
  end

  def perform!(command_string)
    if command_string != "init"
      parsed_command = command_string.split(" ")
      command = parsed_command.slice!(0)
      @history << "#{@current_dir} #{@current_user.nickname}$ #{command_string}"
      if command.present?
        @result = self.respond_to?(command.downcase) ? self.send(command.downcase, parsed_command) : "unrecognized command '#{command}'"
        @history << @result if @result.present?
      end
    else
      init!
    end
  end

  def init!
    @history = [consolize("Initializing #{version}...=br==br=Type 'help' for help=br=")]
    @result = nil
    build_file_system!
  end

  def history
    @history
  end

  def history=(h)
    @history = h
  end

  def current_dir
    @current_dir
  end

  def file_system
    @file_system
  end

  def result
    @result
  end

  def consolize(object, options = {})
    result = case object
    when Array
      longest_prefix = ""
      # längste erste Zelle bestimmen
      object.each do |row|
        row = Array.wrap(row)
        longest_prefix = row.first if row.first.length > longest_prefix.length
      end
      # erste Spalte auf gleiche Breite bringen
      object.each do |row|
        row = Array.wrap(row)
        row[0] = row.first.ljust(longest_prefix.length)
      end
      # Ausgabe
      lines = []
      object.each do |row|
        row = Array.wrap(row)
        lines << "#{row.slice!(0)}#{options[:col_sep].present? ? options[:col_sep] : " "}#{row.present? ? row.join(" ") : ""}"
      end
      lines.join("=br=")
    else
      object
    end

    result.gsub(" ", "&nbsp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("=br=", "<br>").html_safe
  end

  def build_file_system!
    @file_system = { 
      "home/"                     => :dir,
      "home/file_1.txt"           => :file,
      "home/file_2.txt"           => :file,
      "home/folder_1/"            => :dir,
      "home/folder_1/file_3.csv"  => :file,
      "home/folder_2/"            => :dir,
      "home/folder_2/folder_3/"   => :dir,
      "home/trash/"               => :dir
    }
    @current_dir = @file_system.first.first
  end

  def available_sub_folders
    (@file_system.keys.delete_if { |path| @file_system[path] == :file || !path.starts_with?(@current_dir) || path == @current_dir || path.gsub(@current_dir, "").count("/") > 1 }).sort
  end

  def available_sub_files
    (@file_system.keys.delete_if { |path| @file_system[path] == :dir || !path.starts_with?(@current_dir) || path.gsub(@current_dir, "").include?("/") }).sort
  end

  ################################################################################################################################
  # Shell-Commands

  def cd(location = nil)
    location = location.first if location.is_a?(Array)
    not_found = false
    if location.blank?
      @current_dir = @file_system.first.first
    elsif location == "."
      @current_dir
    elsif location == ".."
      if @current_dir != @file_system.first.first
        @current_dir = @current_dir[0 ..@current_dir.chomp("/").rindex("/")]
      else
        @current_dir
      end
    else
      location << "/" unless location.ends_with?("/")
      if available_sub_folders.include?("#{@current_dir}#{location}")
        @current_dir = "#{@current_dir}#{location}"
      else
        not_found = true
      end
    end
    "directory not found: #{location}" if not_found
  end

  def ls(p=nil)
    consolize("total #{(available_sub_folders + available_sub_files).count}=br=.=br=..=br=") << consolize((available_sub_folders + available_sub_files).sort)
  end

  def version(p=nil)
    "ActionShell v0.2"
  end

  def help(p=nil)
    consolize("=br=ActionShell supports the following commands:=br==br=") << consolize([
      ["help", "display this help text"],
      ["ls", "list contents of current directory"],
      ["cd <dir>", "change directory to <dir>"],
      ["version", "show version information"],
      ["exit", "close ActionShell session and return to desktop"]
    ])
  end
end