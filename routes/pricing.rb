require 'net/http'

get '/pricing/?' do
	@breadcrumbs << {:text => 'Material Pricing'}

	erb :pricing, :layout => :fixed, :locals => {
		:content => Net::HTTP.get_response(URI.parse("https://innovationstudio.unl.edu/node/#{drupal_node_lookup(:material_pricing)}?format=partial")).body
	}

end
