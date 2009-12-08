class Pa < ActiveRecord::Base
  has_many :analyses
  has_many :tenements, :through => :analyses
  acts_as_geom :the_geom => :polygon
  set_primary_key :gid
  
  #selects PAs that overlap with input polygon 
  def self.overlaps_with wkt
    return nil unless wkt
    self.find_by_sql "select gid as id from pas where the_geom && ST_GeomFromEWKT('SRID=4326;#{wkt}')"
  end
  
  #selects PAs and the distance to an input polygon
  def self.distance_from wkt
    return nil unless wkt
    self.find_by_sql "select gid as id, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;#{wkt}')) from pas"
  end

  #selects PAs, outputs as geojson with distance that are within 50 degrees of the input polygon
  def self.within_50_degrees_of wkt
    return nil unless wkt
    self.find_by_sql "select gid as id, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;#{wkt}')) from pas where the_geom && ST_Buffer(ST_GeomFromEWKT('SRID=4326;#{wkt}'),50)"
  end

    
end
