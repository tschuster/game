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
        result = link_to(actions_path(type_id: action_id), method: :post, class: "btn btn-primary") do
          '<span class="glyphicon glyphicon-usd" style="width: 61px;"> Buy</span>'.html_safe
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
      result = link_to(actions_path(type_id: action_id), method: :post, class: "btn btn-primary") do
        '<span class="glyphicon glyphicon-collapse-up" style="width: 61px;"> Train</span>'.html_safe
      end
    end
    result.html_safe
  end
end