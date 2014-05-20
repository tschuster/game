# encoding: utf-8
class AiPlayer < User

  def perform_action!
    reload
    return if has_incomplete_actions?
    plan_next_step(strategy)
  end

  # determine, which strategy to use. Can result in :agressive, :defensive and :moderate
  def strategy

    attacks_in_last_24_hours = Action.where(["type_id = ? OR type_id = ?", Action::TYPE_ATTACK_USER, Action::TYPE_ATTACK_USER_DDOS]).where(target_id: id, target_type: "User", completed: true).where("completed_at >= ?", DateTime.now-24.hours).count

    # how often was the player succesfully attacked in the last 24 hours?
    if successful_attacks_in_last_24_hours > 0 && !counterattack_successful?
      agressiveness = (successful_attacks_in_last_24_hours.to_f/attacks_in_last_24_hours.to_f*100).to_i
    else
      agressiveness = 50
    end

    # how many other players can be attacked by this player?
    other_players = User.where(["id != ?", id])
    attack_opportunities   = 0
    stronger_opportunities = 0
    weaker_opportunities   = 0
    total_opportunities = other_players.count*2
    other_players.each do |player|
      [:hack, :ddos].each do |type|
        attack_opportunities   += 1 if can_attack?(player, type)
        weaker_opportunities   += 1 if to_strong_for(player, type)
        stronger_opportunities += 1 if to_weak_for(player, type)
      end
    end

    # assume that own defense is too low if defense is less than 33% of all attributes and more than 25% of other players are stronger
    if (hacking_ratio+defense_ratio+botnet_ratio) > 0 && 
      ((defense_ratio.to_f/(hacking_ratio.to_f+defense_ratio.to_f+botnet_ratio.to_f)*100).round(0) < 33) &&
      (stronger_opportunities.to_f/total_opportunities.to_f*100).round(0) > 25
      defensiveness = 100
    else
      defensiveness = 50
    end

    # determine strategy according to relation between agressiveness and defensiveness
    if agressiveness > defensiveness
Rails.logger.info("---> AI: my strategy is agressive")
      :agressive
    elsif agressiveness < defensiveness
Rails.logger.info("---> AI: my strategy is defensive")
      :defensive
    else
Rails.logger.info("---> AI: my strategy is moderate")
      :moderate
    end
  end

  # determine next step according to strategy
  def plan_next_step(used_strategy)
    options = {}
    case used_strategy
    when :agressive

      # attack a company if success rate is high enough
      attackable_companies = Company.all.delete_if { |c| chance_of_success_against(c, :hack) < 50.0 }
      if attackable_companies.present?
        company_with_highest_success_rate = attackable_companies.sort_by! { |c| chance_of_success_against(c, :hack) }.first
        options = {
          user_id:      id,
          target_id:    company_with_highest_success_rate.id,
          target_type:  "Company",
          type_id:      Action::TYPE_ATTACK_COMPANY,
          completed_at: time_to_attack(company_with_highest_success_rate, :hack)
        }

      # counter-attack last attacker (if his attack is still unavenged)
      elsif successful_attacks_in_last_24_hours > 0 && !counterattack_successful?
        last_attacker = Action.where(["type_id = ? OR type_id = ?", Action::TYPE_ATTACK_USER, Action::TYPE_ATTACK_USER_DDOS]).where(target_id: id, target_type: "User", completed: true, success: true).where("completed_at >= ?", DateTime.now-24.hours).order("completed_at DESC").first.try(:user)
        if last_attacker.present? && 
          (can_attack?(last_attacker, :hack) || can_attack?(last_attacker, :ddos)) && 
          (chance_of_success_against(last_attacker, :hack) >= 50.0 || chance_of_success_against(last_attacker, :ddos) >= 50.0)

          # determine attack type based on success rate and possible reward
          options = {
            user_id:     id,
            target_id:   last_attacker.id,
            target_type: "User"
          }

          # assume that last attacker is rich if he controls a company
          if last_attacker.companies.present?
            options[:type_id] = Action::TYPE_ATTACK_USER
            options[:completed_at] = DateTime.now + time_to_attack(last_attacker, :hack).seconds

          elsif chance_of_success_against(last_attacker, :hack) > chance_of_success_against(last_attacker, :ddos)
            options[:type_id] = Action::TYPE_ATTACK_USER
            options[:completed_at] = DateTime.now + time_to_attack(last_attacker, :hack).seconds

          elsif chance_of_success_against(last_attacker, :hack) <= chance_of_success_against(last_attacker, :ddos)
            options[:type_id] = Action::TYPE_ATTACK_USER_DDOS
            options[:completed_at] = DateTime.now + time_to_attack(last_attacker, :ddos).seconds
          end

        # buy or evolve attack skills
        else
          options = buy_or_evolve_attack
        end
      else
        options = buy_or_evolve_attack
      end
    when :defensive
      options = buy_or_evolve_defense

    when :moderate
      options = if (hacking_ratio <= botnet_ratio && hacking_ratio <= defense_ratio) ||
        (botnet_ratio <= hacking_ratio && botnet_ratio <= defense_ratio)
        buy_or_evolve_attack
      elsif defense_ratio <= botnet_ratio && defense_ratio <= hacking_ratio
        buy_or_evolve_defense
      end
    end

    if options.present?
      if options[:accept_job_id].present? && Job.acceptable.where(id: options[:accept_job_id]).first.present?
Rails.logger.info("---> AI: i accept job# #{options[:accept_job_id]}")
        Job.acceptable.where(id: options[:accept_job_id]).first.accept_by(self)
      else
        result = Action.create(options)
Rails.logger.info("---> AI: i perform #{result.readable_type}")
        result
      end
    end
  end

  private
    def successful_attacks_in_last_24_hours
      Action.where(["type_id = ? OR type_id = ?", Action::TYPE_ATTACK_USER, Action::TYPE_ATTACK_USER_DDOS]).where(target_id: id, target_type: "User", completed: true, success: true).where("completed_at >= ?", DateTime.now-24.hours).count
    end

    def counterattack_successful?
      last_attack = Action.where(["type_id = ? OR type_id = ?", Action::TYPE_ATTACK_USER, Action::TYPE_ATTACK_USER_DDOS]).where(target_id: id, target_type: "User", completed: true, success: true).where("completed_at >= ?", DateTime.now-24.hours).order("completed_at DESC").last
      return false if last_attack.blank?

      my_last_attack = actions.where(["type_id = ? OR type_id = ?", Action::TYPE_ATTACK_USER, Action::TYPE_ATTACK_USER_DDOS]).where(target_id: last_attack.user_id, target_type: "User", completed: true, success: true).first
      my_last_attack.present?
    end    

    def buy_or_evolve_attack
      options = nil
      available_jobs = Job.acceptable.where("hacking_ratio_required = 0 OR (hacking_ratio_required > 0 AND hacking_ratio_required <= ?)", hacking_ratio).where("botnet_ratio_required = 0 OR (botnet_ratio_required > 0 AND botnet_ratio_required <= ?)", botnet_ratio).sort_by! { |job| job.duration_for(self).seconds }

      # increase hacking skill
      if hacking_ratio.to_f < botnet_ratio.to_f*1.3
        if can_buy?(Action::TYPE_HACKING_BUY)
Rails.logger.info("---> AI: i can buy hacking skill")
          options = {
            user_id:      id,
            type_id:      Action::TYPE_HACKING_BUY,
            completed_at: DateTime.now
          }
        elsif next_hacking_ratio_time < available_jobs.last.duration_for(self)
Rails.logger.info("---> AI: i can evolve hacking skill")
          options = {
            user_id:      id,
            type_id:      Action::TYPE_HACKING_EVOLVE,
            completed_at: DateTime.now + next_hacking_ratio_time.seconds
          }
        else
Rails.logger.info("---> AI: i must perform a job to buy hacking skill")
          available_jobs.each do |job|
            options = { accept_job_id: job.id } if (job.reward+money >= next_hacking_ratio_cost) && options.blank?
          end
          options = { accept_job_id: available_jobs.last.id } if options.blank?
        end

      # increase botnet strength
      else
        if can_buy?(Action::TYPE_BOTNET_BUY)
Rails.logger.info("---> AI: i can buy botnet strength")
          options = {
            user_id:      id,
            type_id:      Action::TYPE_BOTNET_BUY,
            completed_at: DateTime.now
          }
        elsif next_botnet_ratio_time < available_jobs.last.duration_for(self)
Rails.logger.info("---> AI: i can evolve botnet strength")
          options = {
            user_id:      id,
            type_id:      Action::TYPE_BOTNET_EVOLVE,
            completed_at: DateTime.now + next_botnet_ratio_time.seconds
          }
        else
Rails.logger.info("---> AI: i must peform a job to buy botnet strength")
          available_jobs.each do |job|
            options = { accept_job_id: job.id } if (job.reward+money >= next_botnet_ratio_cost) && options.blank?
          end
          options = { accept_job_id: available_jobs.last.id } if options.blank?
        end
      end
      options
    end

    def buy_or_evolve_defense
      options = nil
      available_jobs = Job.acceptable.where("hacking_ratio_required = 0 OR (hacking_ratio_required > 0 AND hacking_ratio_required <= ?)", hacking_ratio).where("botnet_ratio_required = 0 OR (botnet_ratio_required > 0 AND botnet_ratio_required <= ?)", botnet_ratio).sort_by! { |job| job.duration_for(self).seconds }

      # increase defense ratio
      if can_buy?(Action::TYPE_DEFENSE_BUY)
Rails.logger.info("---> AI: i can buy defense")
        options = {
          user_id:      id,
          type_id:      Action::TYPE_DEFENSE_BUY,
          completed_at: DateTime.now
        }
      elsif next_defense_ratio_time < available_jobs.last.duration_for(self)
Rails.logger.info("---> AI: i can evolve defense")
        options = {
          user_id:      id,
          type_id:      Action::TYPE_DEFENSE_EVOLVE,
          completed_at: DateTime.now + next_defense_ratio_time.seconds
        }
      else
Rails.logger.info("---> AI: i must perform a job to buy defense")
        available_jobs.each do |job|
          options = { accept_job_id: job.id } if (job.reward+money >= next_defense_ratio_cost) && options.blank?
        end
        options = { accept_job_id: available_jobs.last.id } if options.blank?
      end
      options
    end
end