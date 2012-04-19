class Target < ActiveRecord::Base
  has_many :jobs

  def difficulty
    ratio + rand(5)*10
  end
end
