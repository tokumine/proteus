class AnalysisProximity < Analysis
  
  #selects PAs, outputs as geojson with distance that are within 0.5 degrees of the input polygon
  def self.analyse tenement_id, wkt
    return nil unless wkt
    results = self.find_by_sql "select gid as result_id, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;#{wkt}')) as distance from pas where the_geom && ST_Buffer(ST_GeomFromEWKT('SRID=4326;#{wkt}'),0.5)"
    
   analysis = []
    results.each do |r|
      analysis << self.create(:tenement_id => tenement_id, :pa_id => r.result_id, :name => "proxmity", :value => r.distance)
    end
    analysis
    
  end
  
end