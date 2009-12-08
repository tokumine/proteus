class AnalysisOverlap < Analysis
  
  #selects PAs that overlap with input polygon 
  def self.analyse tenement_id, wkt
    return nil unless wkt
    results = self.find_by_sql "select gid as result_id from pas where the_geom && ST_GeomFromEWKT('SRID=4326;#{wkt}') and name_eng <> 'English name not known'"
  
    analysis = []
    results.each do |r|
      analysis << self.create(:tenement_id => tenement_id, :pa_id => r.result_id)
    end
    analysis
  end
  
end