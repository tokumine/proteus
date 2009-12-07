class Tenement < ActiveRecord::Base
  belongs_to :assesment
  has_many :analyses
  has_many :pas, :through => :analyses
end
