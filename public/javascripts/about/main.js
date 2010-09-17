
	$(document).ready(function() {
		
		var configCraig = {    
		     sensitivity: 10,    
		     interval: 0, 
		     over: function(ev){
									$("#overCraig").show();
				 },
		     timeout: 0, 
		     out: function(ev){
									$("#overCraig").hide();	
				}
		};
		var configSimon = {    
		     sensitivity: 10,    
		     interval: 0, 
		     over: function(ev){
									$("#overSimon").show();
				 },
		     timeout: 0, 
		     out: function(ev){
									$("#overSimon").hide();	
				}
		};
		var configVizz= {    
		     sensitivity: 10,    
		     interval: 0, 
		     over: function(ev){
									$("#overVizz").show();
				 },
		     timeout: 0, 
		     out: function(ev){
									$("#overVizz").hide();	
				}
		};
		var configSoler = {    
		     sensitivity: 10,    
		     interval: 0, 
		     over: function(ev){
									$("#overSoler").show();
				 },
		     timeout: 0, 
		     out: function(ev){
									$("#overSoler").hide();	
				}
		};


		$('#craig').hoverIntent(configCraig);
		$('#simon').hoverIntent(configSimon);
		$('#vizz').hoverIntent(configVizz);
		$('#soler').hoverIntent(configSoler);
		
	});