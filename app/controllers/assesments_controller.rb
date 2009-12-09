class AssesmentsController < ApplicationController
  
  def index 
    if !session[:assesment_ids].blank?
      @assesments = Assesment.all :conditions => ['id IN (?)', session[:assesment_ids]], :order => "created_at DESC"
    else  
      @assesments ||= []
    end 
    
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
        session[:assesment_ids] ||= []
        session[:assesment_ids] << @assesment.id
        
        #READ IN AND CREATE TENEMENTS
        GeoRuby::Shp4r::ShpFile.open(File.join(directory,f)) do |shp|
          shp.each do |shape|
            @assesment.tenements.create :the_geom => shape.geometry, :attribute_data => shape.data
          end        
        end
      end
    end
    
    #WE WOULD NORMALLY ADD TO USER HERE, BUT TEMP IS ADD TO SESSION
    
    #cleanup files
    FileUtils.rm_rf directory
    
    #CONDUCT DISTANCE QUERY AND SAVE IN JOIN TABLE
    @assesment.tenements.each do |t|
      AnalysisOverlap.analyse t.id, t.the_geom.as_wkt
      AnalysisProximity.analyse t.id, t.the_geom.as_wkt
    end

    
    if @assesment
      flash[:notice] = "analysis complete"
    end
    redirect_to root_url
  end
    
    
  def show
    @a = Assesment.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.csv do
        
        require "csv"
        if CSV.const_defined? :Reader
          require 'fastercsv'
          csv_string = FasterCSV.generate do |csv|
            # header row
            csv << ["tenement_id", "wdpa_site_code", "pa_name", "iucn_cat", "designation", "analysis type", "distance"]

            # data rows
            @a.tenements.each do |t|
              t.overlapping_pas.each do |pa|
                csv << [t.id, pa.site_id, pa.name_eng,pa.iucncat,pa.desig_eng,"overlap",-1]
              end
              t.nearby_pas.each do |pa|
                csv << [t.id, pa.site_id, pa.name_eng,pa.iucncat,pa.desig_loc,"nearby",pa.analyses.find_by_tenement_id(t.id).try(:value)]
              end
            end
          end
        else
          csv_string = CSV.generate do |csv|
            # header row
            csv << ["tenement_id", "wdpa_site_code", "pa_name", "iucn_cat", "designation", "analysis type", "distance"]

            # data rows
            @a.tenements.each do |t|
              t.overlapping_pas.each do |pa|
                csv << [t.id, pa.site_id, pa.name_eng,pa.iucncat,pa.desig_eng,"overlap",-1]
              end
              t.nearby_pas.each do |pa|
                csv << [t.id, pa.site_id, pa.name_eng,pa.iucncat,pa.desig_loc,"nearby",pa.analyses.find_by_tenement_id(t.id).try(:value)]
              end
            end
          end

        end
        

        # send it to the browsah
        send_data csv_string,
                 :type => 'text/csv; charset=iso-8859-1; header=present',
                 :disposition => "attachment; filename=tenement_analysis.csv"
      end
    end
  end
  
  
  def json
    @a = Assesment.find(params[:id])
    return_array = []
    @a.tenements.each do |t|
      json_hash = {}
      json_hash[:id] = t.id
      json_hash[:geom] = JSON.parse t.as_geo_json(6,1)
      return_array << json_hash
    end
      
    render :json => return_array.to_json        
  end
  
  def destroy
    a = Assesment.find(params[:id])  
    if a.destroy
      flash[:notice] = "analysis deleted"
    end
    redirect_to root_url
  end
end
