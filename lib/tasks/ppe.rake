# BASIC PATH TO INITIAL TEST DATA
# rake db:drop:all
# rake ppe:delete_data_rec
# rake db:create:all
# rake db:migrate
# rake ppe:wdpa:import_to_temp_table
# rake ppe:library_data:load_all
# rake ppe:wdpa:transfer_6_wdpa
# rake ppe:dummy_data:generate
# rake ppe:data_rec
# rake ppe:feeds:load



#THESE TASKS IMPORT DATA FROM THE WDPA SHAPEFILE
namespace :ppe do 
  
  desc "delete all exported and imported files and directories"
  task :delete_export_import do 
    
  end
  
  desc "delete all data_rec information"
  task :delete_data_rec => :environment do
    FileUtils.rm_rf DR::Config.export_folder
    FileUtils.rm_rf DR::Config.imports_folder_head_location
    for file in ExportLibraries.files
      FileUtils.rm_f file
    end
     
  end
  
  desc "create test user"
  task :create_test_user => :environment do
    User.create :username => "testing", :email => "test@unep-wcmc.org", :password => "testing", :password_confirmation => "testing", :country => Country.first, :title => "mr", :first_name => "Piliper", :last_name => "Grits", :first_login_ip => "88.96.173.198", :latitude => 53.6167, :longitude => -2.15
  end
  
  desc "create fake data_rec stuffs"
  task :data_rec => :environment do
    Export.delete_all
    DataReconciliation.delete_all
    create_fake_exports
    create_fake_data_rec
  end
  
  def create_fake_exports
    #In exported state
    export = Export.new()
    export.user = User.first
    export.has_geometry = false
    export.protected_areas << ProtectedArea.first
    export.protected_areas << ProtectedArea.last
    for pa in export.protected_areas
      pa.maintain_attributes
    end
    export.save!
    FileUtils.mkdir_p DR::Config.export_folder
    FileUtils.mkdir_p DR::Config.imports_folder_head_location  #if exports probably will be imports =)
    ExportLibraries.export
    export.make_export
    
    #In save state
    export = Export.new()
    export.user = User.last
    export.has_geometry = true
    export.protected_areas << ProtectedArea.last
    export.protected_areas[0].maintain_attributes
    export.save!
    
    #In downloaded state
    export = Export.new()
    export.user = User.last
    export.has_geometry = true
    export.protected_areas << ProtectedArea.last
    export.protected_areas[0].maintain_attributes
    export.save!
    FileUtils.mkdir_p DR::Config.export_folder
    FileUtils.mkdir_p DR::Config.imports_folder_head_location  #if exports probably will be imports =)
    ExportLibraries.export
    export.make_export
    export.download
  end
  
  def create_fake_data_rec
    puts "data_rec creation!"
    require 'test/unit/helpers/data_reconciliation_helper_test'
    data_rec = DataReconciliationHelperTest.reconciliation_with_valid_change_shapefile Export.last
    data_rec.user = Export.last.user
    data_rec.save
  end
  
  namespace :wdpa do
    desc "import data from shapefile direct to postgis"
    task :import_to_temp_table => :environment do
      begin
        sh "rm db/wdpa.sql"
      rescue
      end
      
      begin
        sh "shp2pgsql -W LATIN1 -c -i -I -s 4326 lib/data/shp/WDPApol2009_6records.shp public.data_import > db/wdpa.sql"
        sh "psql -h localhost -d ppe_development -U ppe < db/wdpa.sql"
        sh "rm db/wdpa.sql"
      rescue
        throw "ensure that WDPApol2009_6records.shp and associated files are inside your lib/data/shp directory."
      end
    end
    
     desc "import data from shapefile direct to postgis"
      task :import_us_to_temp_table => :environment do
        begin
          sh "rm db/wdpa.sql"
        rescue
        end

        begin
          sh "shp2pgsql -W LATIN1 -c -i -I -s 4326 lib/data/shp/WDPA_clusterofSites_US.shp public.data_import > db/wdpa.sql"
          sh "psql -h localhost -d ppe_development -U ppe < db/wdpa.sql"
          sh "rm db/wdpa.sql"
        rescue
          throw "ensure that WDPA_clusterofSites_US.shp and associated files are inside your lib/data/shp directory."
        end
      end
    
    
    desc "import all WDPA data from shapefile direct to postgis"
    task :import_all_to_temp_table => :environment do
      begin
        sh "rm db/wdpa.sql"
      rescue
      end
      
      begin
        sh "shp2pgsql -W LATIN1 -c -i -I -s 4326 lib/data/shp/WDPApol2009.shp public.data_import > db/wdpa.sql"
        sh "psql -h localhost -d ppe_development -U ppe < db/wdpa.sql"
        sh "rm db/wdpa.sql"
      rescue
        throw "ensure that WDPApol2009.shp and associated files are inside your lib/data/shp directory. you can download them here: http://wdpa.s3.amazonaws.com/WDPApol2009_1.zip"
      end
    end
    
    
    desc "transfer first WDPA site into new schema"
    task :transfer_1_wdpa => :environment do
      if ready_to_import?
        import_from_wdpa DataImport.first 
      end
    end
    
    desc "transfer 6 WDPA sites into new schema"
    task :transfer_6_wdpa => :environment do
      if ready_to_import?
        sites = [366165, 377207, 2027, 2628, 1234, 99653]
        puts "\t*** PULLING IN SITES IDS: #{sites.join(", ")} ***"
        DataImport.all(:conditions=> ["site_id IN (?)", sites]).each do |pa|
          import_from_wdpa pa
        end
      end
    end
    
    desc "reset postgres primary key counter"
    task :reset_pg_key => :environment do
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE sites_id_seq RESTART #{DataImport.maximum('site_id')+1};") 
    end
    
    
    desc "transfer all WDPA into new schema"
    task :transfer_all_wdpa => :environment do
      if ready_to_import?
        puts "\t*** PULLING IN ALL WDPA ***"
        f = File.open("lib/errors.txt", 'w+')
        chunksize = 25
        x = 0
        until x > DataImport.count do
          DataImport.all(:limit => chunksize, :offset => x).each do |pa|
            import_from_wdpa pa
          end
          x += chunksize
        end        
      end
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE sites_id_seq RESTART #{DataImport.maximum('site_id')+1};") 
    end
    
    
    def ready_to_import?
      IucnCategory.count == 0 ? throw("Nothing in Library tables. run rake ppe:library_data:load_all first") : true      
    end
    
    def import_from_wdpa pa
      begin
        puts "\t**Importing #{pa.name_eng}"
        import_pa pa
      rescue => e
        puts pa.gid.to_s + ", " + e.backtrace.join("\n") 
      end
    end
    
    def import_pa data_import, pa=nil
      #SETUP
      apa = AbstractPa.create
      site = Site.create(:abstract_pa => apa) do |site| 
        site.id = data_import.site_id 
      end
      pa = ProtectedArea.create :site => site
      
      #WDPA - now the actual PK
      #site.wdpa_code = data_import.site_id if data_there?(data_import.site_id)
      
      #NAME
      pa.english_name = data_import.name_eng if data_there? data_import.name_eng
      pa.local_name = data_import.name_loc if data_there? data_import.name_loc
      
      #IUCN CATEGORY
      #puts "iucn cat is #{data_import.iucncat}"
      pa.iucn_category = IucnCategory.first(:conditions => "name = '#{data_import.iucncat}'") if data_there? data_import.iucncat
      
      #ISO3
      pa.countries << Country.first(:conditions => "iso_3 = '#{data_import.iso3}'")
      
      #DESIGNATION
      designation = nil
      if (data_there? data_import.desig_eng)
        designation = Designation.first :joins => :jurisdiction, :conditions => "designations.name = '#{data_import.desig_eng}' AND jurisdictions.name = 'National'"  
      elsif (data_there? data_import.int_conv.chomp)
        designation = Designation.first :joins => :jurisdiction, :conditions => "designations.name = '#{data_import.int_conv}' AND jurisdictions.name = 'International'"    
      end
      pa.designation = designation
      
      #STATUS_DATE  
      day =  (data_there? data_import.status_d && data_import.status_d > 0) ? data_import.status_d : 1    
      month = (data_there? data_import.status_m && data_import.status_m > 0) ? data_import.status_m : 1
      year =  (data_there? data_import.status_yr && data_import.status_yr > 0) ? data_import.status_yr : 0001
      pa.status_date = Date.civil(year,month,day)
      pa.valid_from = pa.status_date  
      pa.legal_status = LegalStatus.first(:conditions => "name='#{data_import.status}'") if (data_there? data_import.status)
      
      #AREA + LAND_TYPE
      #Create area link
      if (data_there? data_import.doc_area_h && data_import.doc_area_h > 0)
        pa.total_area = data_import.doc_area_h
      end
      if (data_there? data_import.doc_m_area && data_import.doc_m_area > 0)
        pa.total_area_marine = data_import.doc_m_area
      end  
      
      #DATA SOURCE
      if (data_there? data_import.source)
        puts "\t**ADDING #{pa.english_name} TO #{data_import.source} DATASET"
        pa.dataset = Dataset.first(:conditions => "citation = '#{data_import.source}'")
      else
        puts "\t**ADDING #{pa.english_name} TO WDPA v1 DATASET"
        pa.dataset = Dataset.find_by_citation("WDPA v1")
      end
      
      #GEOMETRY
      if (data_there? data_import.the_geom)
        the_geom = PolygonGeom.create(:the_geom => data_import.the_geom)
        pa.polygon_geom = the_geom
      end
      
      #USER
      pa.user = User.find_by_username "WCMC"
      
      pa.save #TODO: SET ALL THE EDIT_ID's (MAYBE)
      puts pa.errors.inspect unless pa.errors.empty?
      
      begin
        pa.complete!
      rescue Exception => e
        "***#{pa.english_name} is not complete. Cannot transfer to complete state"  
      end
      puts "#{pa.english_name} is now #{pa.state}"
      
    end
    
    
  end
  
  
  
  
  #THESE TASKS POPULATE LIBRARY DATA TABLES
  namespace :library_data do
    #LIBRARY TABLES    
    desc "populate all library tables"
    task :load_all => :environment do
      if DataImport.count == 0
        throw "Nothing in DataImport table. Run rake ppe:wdpa:import_to_temp_table first" 
      end
      
      
      #POPULATE
      Rake::Task['ppe:library_data:load_countries'].invoke
      Rake::Task['ppe:library_data:load_iucn_cat'].invoke 
      Rake::Task['ppe:library_data:load_jurisdiction'].invoke  
      Rake::Task['ppe:library_data:load_designation_and_status_from_wdpa'].invoke
      Rake::Task['ppe:library_data:load_sources'].invoke
      
    end
    
    desc "populate dataset table"
    task :load_sources => :environment do
      Dataset.delete_all
      
      #CREATE BASE WCMC USER
      User.create :username => "WCMC", :email => "wdpa@unep-wcmc.org", :password => "xxxxxx", :password_confirmation => "xxxxxx", :country => Country.first, :title => "mr", :first_name => "asdfs", :last_name => "asdfasd", :first_login_ip => "88.96.173.198", :latitude => 53.6167, :longitude => -2.15
      
      user = User.find_by_username "WCMC"
      Dataset.create :citation => "WDPA v1", :user => user
      sources = DataImport.find_by_sql(["SELECT DISTINCT(source) from data_import"])
      sources.each do |source|   
        if (data_there? source.source)
          Dataset.create :citation => source.source, :user => user
        end
      end
    end
    
    desc "populate countries table"
    task :load_countries => :environment do 
      #CREATE REGION CODES AND LOAD DATA
      Region.delete_all
      Region.create(:name => 'Africa', :code => 'AF')
      Region.create(:name => 'Asia', :code => 'AS')
      Region.create(:name => 'Europe', :code => 'EU')
      Region.create(:name => 'North America', :code => 'NA')
      Region.create(:name => 'Oceania', :code => 'OC')
      Region.create(:name => 'South America', :code => 'SA')
      Region.create(:name => 'Antarctica', :code => 'AN')
      Region.create(:name => 'Oceans', :code => 'OO')
      
      Country.delete_all
      File.open("lib/data/txt/countryInfo.txt").each do |record|
        c = record.split("\t")
        Country.create(:iso => c[0], :iso_3 => c[1], :name => c[4], :region_id => Region.find_by_code(c[8]).id)
      end       
    end
    
    desc "populate Iucn Categories table"
    task :load_iucn_cat => :environment do
      IucnCategory.delete_all
      cats = %w(Ia Ib II III IV V VI)
      cats.each_with_index do |cat,index|
        IucnCategory.create :name => cat, :value => index
      end
    end
    
    desc "populate jurisdiction table"
    task :load_jurisdiction => :environment do
      Jurisdiction.delete_all
      Jurisdiction.create :name => "National"
      Jurisdiction.create :name => "International"
    end
    
    desc "populate data tables from postgis import"
    task :load_designation_and_status_from_wdpa => :environment do
      #DELETE
      Designation.delete_all
      LegalStatus.delete_all
      
      #DESIGNATION - NATIONAL & INTERNATIONAL
      results = DataImport.find_by_sql(["SELECT DISTINCT(desig_eng) from data_import"])
      results.each do |desig|   
        if (data_there? desig.desig_eng)
          d = Designation.create :name => desig.desig_eng
          d.jurisdiction = Jurisdiction.first :conditions =>  "name='National'"
          d.save
        end
      end
      
      results = DataImport.find_by_sql(["SELECT DISTINCT(int_conv) from data_import"])
      results.each do |desig|
        if (data_there? desig.int_conv)
          d = Designation.create :name => desig.int_conv
          d.jurisdiction = Jurisdiction.first :conditions => "name='International'"
          d.save
        end
      end
      
      #LEGAL STATUS
      results = DataImport.find_by_sql(["SELECT DISTINCT(status) from data_import"])
      results.each do |rec|
        if (data_there? rec.status)
          LegalStatus.create :name => rec.status
        end
      end
    end
  end
  
  
  
  
  #THESE TASKS CREATES DUMMY USERS, AND A LOAD OF DATA AROUND THE PABS
  namespace :dummy_data do
    desc "purge randomly generated content"
    task :purge => :environment do
      DbpediaAbstract.delete_all
      User.delete_all("id != 1")
      Comment.delete_all
      News.delete_all
      Shout.delete_all
      Visit.delete_all
    end
    
    desc "populate db with dummy data"
    task :generate => :environment do
      User.delete_all("id != 1")
      puts "***Importing Users, this will take time***"
      chars = %w{ | / - \\ }
      countries = Country.all.map{|c|c.id}
      2.times do 
        user = User.new 
        user.title = ["Mr", "Mrs", "Ms"].rand
        user.first_name = Faker::Internet.user_name
        user.last_name = Faker::Internet.user_name
        user.username = Faker::Internet.user_name
        user.email = Faker::Internet.email
        user.url = "http://" + Faker::Internet.domain_name + "/" + Faker::Lorem.sentence(1)
        user.password = Faker::Lorem.words(6)
        user.password_confirmation = user.password
        user.country_id = countries.rand
        user.first_login_ip = fake_ip 
        loc = GeoIp.remote_localization(user.first_login_ip)
        user.latitude = loc["Latitude"]
        user.longitude = loc["Longitude"]
        user.save
        puts user.errors.inspect unless user.errors.empty?
        puts "added user: #{user.username}"
      end
      
      ProtectedArea.all.each do |pa|
        puts "Generating dummy data for #{pa.english_name}" 
        populate_pa_with_dummy_data pa.site
      end
      
      puts "*" * 20
      puts "Dummy data complete. You now have:"
      puts "#{News.count} news stories and #{User.count} users with #{Comment.count} comments, #{Shout.count} shouts, and #{Visit.count} visits."
      puts "*" * 20
    end   
    
    
    
    def populate_pa_with_dummy_data site
      
      #NEWS
       (0..10).to_a.rand.times do
        site.news << News.create(:title => Faker::Company.catch_phrase, :url => "http://" + Faker::Internet.domain_name + "/" + Faker::Lorem.sentence(1)) 
      end
      
      User.all.each do |user|
        #SHOUTS        
        user.shouted_sites << site if flip_coin
        
        #COMMENTS
        user.commented_sites.push_with_attributes(site, :body => Faker::Lorem.paragraph(3)) if flip_coin
        
        #VISITS
        user.visited_sites << site if flip_coin
      end
    end 
  end  
  
  
  
  
  #THESE TASKS LOAD FEEDS FROM DBPEDIA AND PANORAMIO  
  namespace :feeds do
    #TODO. refactor to a generic table name (feeds) and add feed_types table.
    desc "purge dbpedia and poi content"
    task :purge => :environment do
      DbpediaRdf.delete_all
      DbpediaAbstract.delete_all
    end
    
    desc "load poi content"
    task :load => :environment do
      #NUKE ALL IMAGES & RESET DB
      require 'fileutils'
      PointOfInterest.delete_all
      Image.delete_all      
      FileUtils.rm_rf "#{RAILS_ROOT}/ppe/public/system/pa_images"
      
      ProtectedArea.all.each do |pa|
        load_feeds pa
      end
    end
    
    #LOADS ALL FEEDS FOR PA NAMES AND GEOMETRY
    def load_feeds pa
      
      #REMOVE ALL IMAGES FOR THE PA
      pa.site.delete_images
      
      #LOAD SAMPLE IMAGES FOR THE PA FROM PANORAMIO
      Image.load_from_panoramio pa, pa.site
      
      #LOAD SAMPLE POI'S & THEIR IMAGES FROM WIKIPEDA/GEONAMES
      PointOfInterest.load_from_geonames pa

      #SHOULD GET THE dbpedialookup GEM WORKING
      #wiki_uri = Dbpedia.sparql pa.english_name
      #puts wiki_uri
      #Dbpedia.load wiki_uri, pa.site


      #COMMENTED AS HAVE NO LOCAL NAME FOR MANY
      #wiki_uri = Dbpedia.sparql pa.local_name
      #Dbpedia.load wiki_uri, pa.site    

    end

    
  end    
  
  
  
  
  
  
  
  
  
  
  
  ################
  # HELPER METHODS
  #
  
  # TESTS FOR COMMON ARTIFACTS IN THE WDPA WHICH MEAN "NULL". 
  # THIS HAS BEEN NECCESSARY AS FOXPRO/SHAPEFILES CANNOT CONTAIN NULL VALUES.
  def data_there?(data)
    null_words = ["Not applicable", "NULL", "Not Known", "Not Applicable", "Local name not known"]
     (data && !data.blank? && !null_words.include?(data)) ? true : false
  end    
  
  # D2 - coin toss
  def flip_coin
    rand > 0.5
  end
  
  def fake_ip
    [rand(254),rand(254),rand(254),rand(254)].join(".")
  end
  
  #################
  # This particular task is a bit of a pain to run
  #
  # In order to run it, you must:
  # * commit all changes to git to date. You are about to trash your local codebase 
  #   in the quest for pretty diagramz.
  # * have Railroad gem installed with graphiz (http://github.com/bryanlarsen/railroad)
  # * comment out the AR inheritance, and all code in data_import.rb model class file
  # * run rake ppe:doc:diagram:models
  # * wait for a weird crash
  # * check your doc directory for the nice model.pdf
  # * undo all your comments from above
  # * git add .
  # * git commit -a -m "updated nice diagrams"
  #
  #
  # I REALLY need to package all this up into a simple rake task...
  namespace :doc do
    namespace :diagram do
      
      desc "Fancy model diagrams in /doc"
      task :models do
        sh "railroad -i -l -a -m -M | dot -Tpdf | sed 's/font-size:14.00/font-size:11.00/g' > doc/models.pdf"
      end
      
      desc "Fancy controller diagrams in /doc"
      task :controllers do
        sh "railroad -i -l -C | neato -Tpdf | sed 's/font-size:14.00/font-size:11.00/g' > doc/controllers.pdf"
      end
    end
    
    desc "model AND Controller diagrams in /doc"
    task :diagrams => %w(diagram:models diagram:controllers)
  end
end

require 'rcov/rcovtask'

desc "Create a cross-referenced code coverage report."
Rcov::RcovTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit/*_test.rb'] #t.test_files = FileList['test/**/*_test.rb']
  t.rcov_opts << "--exclude \"test/*,app/controllers/*,app/helpers/*,gems/*,/Library/Ruby/*,config/*\" --rails" 
end