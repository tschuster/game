module ActionsHelper
  def action_button_for(action_id)
    result = ""
    if [
      Action::TYPE_BOTNET_BUY,
      Action::TYPE_HACKING_BUY,
      Action::TYPE_DEFENSE_BUY
    ].include?(action_id)
      if @current_action.present? && !@current_action.can_be_canceled?
        result = '<span class="btn btn-default disabled">System down</span>'
      elsif current_user.can_buy?(action_id)
        result = link_to(actions_path(type_id: action_id), method: :post, class: "btn btn-primary", style: "width: 82px;") do
          '<span class="glyphicon glyphicon-usd"></span> Buy'.html_safe
        end
      else
        result = '<span class="btn btn-default disabled">Insufficent Funds</span>'
      end
      return result.html_safe
    end

    if @current_action.present?
      if @current_action.can_be_canceled?
        result = '<span class="btn btn-default disabled">Action pending</span>'
      else
        result = '<span class="btn btn-default disabled">System down</span>'
      end
    else
      result = link_to(actions_path(type_id: action_id), method: :post, class: "btn btn-primary", style: "width: 82px;") do
        '<span class="glyphicon glyphicon-collapse-up"></span> Train'.html_safe
      end
    end
    result.html_safe
  end

  def company_action_button_for(action_id, company)
    result = ""

    if @current_action.present?
      result = '<span class="btn btn-default disabled">Action pending</span>'
    elsif [Action::TYPE_COMPANY_INCOME_BUY, Action::TYPE_COMPANY_DEFENSE_BUY].include?(action_id)
      if current_user.can_buy_for_company?(action_id, company)
        result = link_to(actions_path(type_id: action_id, target_id: company.id), method: :post, class: "btn btn-primary", style: "width: 102px;") do
          '<span class="glyphicon glyphicon-usd"></span> Buy'.html_safe
        end
      else
        result = '<span class="btn btn-default disabled">Isufficient funds</span>'
      end
    else
      result = link_to(actions_path(type_id: action_id, target_id: company.id), method: :post, class: "btn btn-primary", style: "width: 102px;") do
        '<span class="glyphicon glyphicon-collapse-up"></span> Increase'.html_safe
      end
    end

    result.html_safe
  end
end