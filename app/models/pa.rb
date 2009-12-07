class Pa < ActiveRecord::Base
  has_many :analyses
  has_many :tenements, :through => :analyses  
end
