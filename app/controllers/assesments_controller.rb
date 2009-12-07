class AssesmentsController < ApplicationController
  
  def index 
    @assesment = Assesment.new
  end
  
  def create
    debugger
    @assesment = Assesment.new(params[:assesment])
    
    redirect_to root_url
    debugger
  end
end
