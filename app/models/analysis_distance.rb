class AnalysisDistance < Analysis
  #selects PAs and the distance to an input polygon
  def self.analyse tenement_id, wkt
    return nil unless wkt
    results = self.find_by_sql "select gid as result_id, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;#{wkt}')) as distance from pas"
    
    analysis = []
    results.each do |r|
      analysis << self.create(:tenement_id => tenement_id, :pa_id => r.result_id, :name => "distance", :value => r.distance)
    end
    analysis
  end  
end