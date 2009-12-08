class AssesmentsController < ApplicationController
  
  def index 
    @assesments = Assesment.all :order => "created_at DESC"
    @assesment = Assesment.new
  end
  
  def create
    file_name = params[:assesment][:shape].original_filename
    
    #test file ending    
    if !file_name.ends_with? ".zip" 
      flash[:notice] = "You must import a zip file"
      redirect_to root_url
      return
    end
        
    #GENERATE INDIVIDUAL FOLDER
    directory_name = Digest::SHA1.hexdigest("#{Time.now.usec}#{file_name}")
    directory = "#{RAILS_ROOT}/tmp/shape_uploads/#{directory_name}"
                                
    #BUILD FOLDER IF NOT THERE
    FileUtils.mkdir_p directory
    
    #create the total file path to save file
    path = File.join(directory, file_name)
        
    # write the file
    File.open(path, "wb") { |f| f.write(params[:assesment][:shape].read) }
    
    #Crack open the zip
    Zip::ZipFile.open(path) do |zip_file|
      zip_file.each do |f|
        real_file_name = f.name.split("/").last
        file_path = File.join(directory, real_file_name)
        zip_file.extract(f, file_path)
      end
    end
    
    #open the shape files and read em in
    Dir.new(directory).each do |f|
      if f.ends_with? ".shp"
        #CREATE ASSESSMENT
        @assesment ||= Assesment.create(:file_name => file_name)
        
        #READ IN AND CREATE TENEMENTS
        GeoRuby::Shp4r::ShpFile.open(File.join(directory,f)) do |shp|
          shp.each do |shape|
            @assesment.tenements.create :the_geom => shape.geometry, :attribute_data => shape.data
          end        
        end
      end
    end
    
    #cleanup
    FileUtils.rm_rf directory
    
    if @assesment
      flash[:notice] = "file saved"
    end
    redirect_to root_url
  end
    
end
