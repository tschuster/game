# encoding: utf-8
class ActionShell

  def initialize(options={})
    @history            = options[:history]
    @current_dir        = options[:current_dir]
    @file_system        = options[:file_system]
    @current_user       = options[:current_user]
    @current_connection = options[:current_connection]
    @password_retry     = options[:password_retry]
    @authenticated      = options[:authenticated]
    @clients            = options[:clients]
  end

  def perform!(command_string, delegate = nil)
    if command_string != "init"
      parsed_command = command_string.split(" ")
      command = parsed_command.slice!(0)

      # if the input is to be delegated to a specific method...
      if delegate.present?
        @history = nil
        @result = self.respond_to?(delegate.downcase) ? self.send(delegate.downcase, command) : nil

      # the default command evaluation
      else
        @history = "#{@current_dir} #{@current_user.nickname}$ #{command_string}"
        if command.present?
          @result = self.respond_to?(command.downcase) ? self.send(command.downcase, parsed_command) : "unrecognized command '#{command}'"
        end
      end
      @result << "<script>$('.prompt').html('#{command_prompt}');</script>".html_safe if @result.present?
    else
      init!
    end
  end

  def init!
    @history = consolize("Initializing #{version}...=br==br=Type 'help' for help=br=")
    @result = nil
    @current_connection = nil
    @password_retry = 0
    build_file_system!
    build_clients!
  end

  def history
    @history
  end

  def current_dir
    @current_dir
  end

  def current_connection
    @current_connection
  end

  def file_system
    @file_system
  end

  def result
    @result
  end

  def clients
    @clients
  end

  def password_retry
    @password_retry
  end

  def authenticated
    @authenticated
  end

  def command_prompt
    if @current_connection.present?
      "#{@clients[@current_connection][:ip]}/#{@clients[@current_connection][:nickname]}$&nbsp;".html_safe
    else
      "#{@current_dir} #{@current_user.nickname}$&nbsp;".html_safe
    end
  end

  def password_retry_limit_reached?
    @password_retry >= 3
  end

  def reset_connection!
    @password_retry = 0
    @current_connection = nil
    @authenticated = false
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

  def random_password(length)
    o = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
    (0..length).map{o[rand(o.length)]}.join
  end

  def build_clients!
    @clients = {}
    User.all.each do |u|
      next if u.id == @current_user.try(:id)

      random_ip = "#{rand(253)+1}.#{rand(256)}.#{rand(256)}.#{rand(253)+1}"
      password = random_password(10)
      @clients[u.nickname] = { :nickname => u.nickname, :id => u.id, :ip => random_ip, :password => password, :type => :user }
      @clients[random_ip]  = { :nickname => u.nickname, :id => u.id, :ip => random_ip, :password => password, :type => :ip }
    end
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
    "ActionShell v0.4 build 2012-06-08"
  end

  def help(p=nil)
    consolize("=br=ActionShell supports the following commands:=br==br=") << consolize([
      ["help", "display this help text"],
      ["ls", "list contents of current directory"],
      ["cd <dir>", "change directory to <dir>"],
      ["version", "show version information"],
      ["exit", "close ActionShell session and return to desktop"],
      ["ping <name|ip>", "ping a client via name to resolve the ip, or via ip to resolve the name"],
      ["connect <ip>", "establish a connection to the given ip after entering the client's password"]
    ])
  end

  def ping(ip_or_nickname = nil)
    return "name or ip must be given" if ip_or_nickname.blank?
    ip_or_nickname = ip_or_nickname.first
    result = @clients[ip_or_nickname]
    if result.present?
      if result[:type] == :ip
        "resolving #{result[:ip]}: #{result[:nickname]}"
      else
        "resolving #{result[:nickname]}: #{result[:ip]}"
      end
    else
      "client unknown: #{ip_or_nickname}"
    end
  end

  def connect(ip)
    return if @current_user.blank?
    return "ip must be given" if ip.blank?
    ip = ip.first
    client = @clients[ip]
    return "connection to #{ip} failed" if client.blank?
    victim = User.find(client[:id])
    return "connection to #{ip} failed" if victim.blank?

    # Set current connection
    @current_connection = client[:nickname]
    @password_retry = 0

    # The standard line length when both players have even strength
    base_line_length = 75
    delta = 25

    # Attacker stronger than victim
    if @current_user.hacking_ratio > victim.defense_ratio
      percentage_stronger = (@current_user.hacking_ratio.to_f / [victim.defense_ratio.to_f, 1].max).round(2)-1
      effective_line_legth = [(base_line_length-percentage_stronger*delta).round(0), 50].max

    # Attacker weaker than victim
    else
      percentage_weaker = (victim.defense_ratio.to_f / [@current_user.hacking_ratio.to_f, 1].max).round(2)-1
      effective_line_legth = [(base_line_length+percentage_stronger*delta).round(0), 100].min
    end

    # Display password stream
    result = "Establishing connection to #{ip}...=br==br="
    20.times do
      line = random_password(rand(effective_line_legth - client[:password].length)) << client[:password]
      line << random_password(effective_line_legth - line.length - 1)
      line << "=br="
      result << line
    end
    result << "=br=Password required!"
    consolize(result) << "<script>$('#delegate').val('check_password');</script>".html_safe
  end

  def check_password(password)
    return "No connection active" if @current_connection.blank?
    if password_retry_limit_reached?
      reset_connection!
      return consolize("Password invalid!=br=Disconnected")
    end
    victim = @clients[@current_connection]

    # Password incorrect - increase retry or disconnect
    if password != victim[:password]
      @password_retry += 1
      if password_retry_limit_reached?
        reset_connection!
        consolize("Password invalid!=br=Disconnected")
      else
        consolize("Password invalid!") << "<script>$('#delegate').val('check_password');</script>".html_safe
      end
    else
      @authenticated = true
      @password_retry = 0
      consolize("Password valid=br==br=Connection to #{victim[:ip]} established")
    end
  end
end