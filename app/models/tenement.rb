class Tenement < ActiveRecord::Base
  belongs_to :assesment
  has_many :analyses, :dependent => :destroy
  has_many :pas, :through => :analyses
  has_many :overlapping_pas, :through => :analyses, 
                             :source => :pa,
                             :conditions => "analyses.type = 'AnalysisOverlap'",
                             :order =>'pas.name_eng ASC'
  has_many :nearby_pas,     :through => :analyses, 
                            :source => :pa,
                            :conditions => "analyses.type = 'AnalysisProximity'",
                            :order =>'pas.name_eng ASC'
  
  acts_as_geom :the_geom => :polygon
  
end
