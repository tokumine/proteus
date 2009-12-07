class Assesment < ActiveRecord::Base
  belongs_to :user
  has_many :tenements
  
  has_attached_file :shape, :url => ""
  validates_attachment_presence :shape
  validates_attachment_content_type :shape, :content_type => ['application/zip','file/zip']
  
  def after_post_process
    logger.fatal "aSFASFsafsadfasdfasdf"
  end
end
