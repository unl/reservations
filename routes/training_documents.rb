require 'net/http'

get '/training-documents/?' do
	@breadcrumbs << {:text => 'Training Documents'}
	erb :training_documents, :layout => :fixed
end

get '/training-documents/sop/?' do
	@breadcrumbs << {:text => 'Training Documents', :href => '/training-documents'}
	@breadcrumbs << {:text => 'SOP'}

	erb :sop_training_document, :layout => :fixed, :locals => {
		:content => Net::HTTP.get_response(URI.parse("https://innovationstudio.unl.edu/node/#{drupal_node_lookup(:sop_training_doc)}?format=partial")).body
	}
end

get '/training-documents/workshops/?' do
	@breadcrumbs << {:text => 'Training Documents', :href => '/training-documents'}
	@breadcrumbs << {:text => 'Workshops'}

	erb :workshops_training_document, :layout => :fixed, :locals => {
		:content => Net::HTTP.get_response(URI.parse("https://innovationstudio.unl.edu/node/#{drupal_node_lookup(:workshops_training_doc)}?format=partial")).body
	}
end

get '/training-documents/tips-and-tricks/?' do
	@breadcrumbs << {:text => 'Training Documents', :href => '/training-documents'}
	@breadcrumbs << {:text => 'Tips and Tricks'}

	erb :tips_and_tricks_training_document, :layout => :fixed, :locals => {
		:content => Net::HTTP.get_response(URI.parse("https://innovationstudio.unl.edu/node/#{drupal_node_lookup(:tips_training_doc)}?format=partial")).body
	}
end