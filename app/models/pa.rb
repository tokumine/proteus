class Pa < ActiveRecord::Base
  has_many :analyses
  has_many :tenements, :through => :analyses
  acts_as_geom :the_geom => :polygon
  set_primary_key :gid
    
end
