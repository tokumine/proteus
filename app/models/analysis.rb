class Analysis < ActiveRecord::Base
  belongs_to :tenement
  belongs_to :pa
  acts_as_geom :the_geom => :polygon
  
end
