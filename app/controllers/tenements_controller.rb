class TenementsController < ApplicationController
  layout 'base_layout'
  
  def show
    @t = Tenement.find(params[:id], :include => :sites)
    @a = Assesment.find(params[:assesment_id])
    @images = @t.sites.map{|s| s.image }.flatten.compact
    @protected_area = Site.sum(:query_area_protected_km2, :conditions => "tenements.id = #{@t.id}", :joins => [:tenement])
    @total_area     = @t.query_area_km2
    @percent_protected = (@protected_area/@total_area)     
    
    
    @map_json = @t.sites(:select => "*, x(ST_PointOnSurface(the_geom)) as x, 
                                        y(ST_PointOnSurface(the_geom)) as y, 
                                        ST_AsGeoJSON(the_geom, 6,0) as geojson").map {|s|        
        {:id          => s.id,
         :wdpaid      => s.wdpaid,
         :name        => s.name,         
         :local_name  => "#{s.percent_affected}% protection",
         :x           => s.x,#.center.x,                       
         :y           => s.y,#.center.y,
         :the_geom    => JSON.parse(s.geojson),
         :pois        => 0,
         :image       => Gchart.pie(:data => [s.percent_affected, 100-s.percent_affected], 											 
 											 :size => "150x150", :background => "ffffff", :custom => "chco=#{pie_colors.join("|")}")}      
    }.to_json
  end

end
