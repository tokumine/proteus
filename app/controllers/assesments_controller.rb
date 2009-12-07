class AssesmentsController < ApplicationController
  
  def index 
    @assesment = Assesment.new
  end
  
  def create
    name = params[:assesment][:shape].original_filename
    
    #test file ending    
    if !name.ends_with? ".zip" 
      flash[:notice] = "You must import a zip file"
      redirect_to root_url
      return
    end
        
    #GENERATE INDIVIDUAL FILENAME
    file_path = "#{Digest::SHA1.hexdigest("#{Time.now.usec}#{name}")}.zip"
    directory = "#{RAILS_ROOT}/data/assesment_shapes/#{file_path}"
        
    #BUILD DIRECTORY IF NOT THERE
    FileUtils.mkdir_p directory
    
    # create the file path
    # path = File.join(directory, file_name)
        
    # write the file
    File.open(path, "wb") { |f| f.write(params[:assesment][:shape].read) }
    
    @assesment = Assesment.new(:shape_file_name => file_name)
    if @assesment.save
      flash[:notice] = "file saved"
    end
    redirect_to root_url
  end
    
end
