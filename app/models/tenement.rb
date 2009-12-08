class Tenement < ActiveRecord::Base
  belongs_to :assesment
  has_many :analyses, :dependent => :destroy
  has_many :pas, :through => :analyses
  acts_as_geom :the_geom => :polygon
  
end
