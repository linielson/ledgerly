class VulnerableController < ApplicationController
  def show
    render plain: eval(params[:expr])
  end
end
