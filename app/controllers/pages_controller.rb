class PagesController < ApplicationController
  before_filter :set_page

  def show
    if @page.blank?
      redirect_to(root_url)
    else
      render @page.to_s
    end
  end

  protected

    def set_page
      @page = params[:id]
    end
end