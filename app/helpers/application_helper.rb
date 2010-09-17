# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def javascript_environment
    "environments/#{ENV['RAILS_ENV'].downcase}"
  end
  
  def pie_colors
    [ "377EB8","E44544", "4DAF4A", "984EA3", "FF7F00" ]
  end    
  
end
