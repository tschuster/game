class Notifier < ActionMailer::Base
  default from: "game@derschuster.de"

  def attacked(user)
    return if user.email.blank? || !user.notify?
    @nickname = user.nickname
    mail(to: "#{user.nickname} <#{user.email}>", subject: "You have been attacked!")
  end

  def intruder_alert(user)
    return if user.email.blank? || !user.notify?
    @nickname = user.nickname
    mail(to: "#{user.nickname} <#{user.email}>", subject: "Intruder alert!")
  end
end