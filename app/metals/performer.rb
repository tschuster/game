# Allow the metal piece to run in isolation
require File.expand_path('../../../config/environment',  __FILE__) unless defined?(Rails)

# Führt alle *jetzt* zur Verarbeitung anstehenden Aktionen aus
class Performer
  class << self
    def call(env)
      if env["PATH_INFO"] =~ /^\/actions\/perform/

        Action.incomplete.to_be_completed.each do |action|
          action.perform!
        end

        [200, {}, []]
      else
        [404, {}, []]
      end
    end
  end
end