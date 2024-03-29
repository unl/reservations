require 'net/http'

get '/training-documents/?' do
	@breadcrumbs << {:text => 'Training Documents'}
	erb :training_documents, :layout => :fixed
end

get '/training-documents/sop/?' do
	@breadcrumbs << {:text => 'Training Documents', :href => '/training-documents'}
	@breadcrumbs << {:text => 'SOP'}

	erb :sop_training_document, :layout => :fixed, :locals => {
		:content => Net::HTTP.get_response(URI.parse("https://innovationstudio.unl.edu#{drupal_link_lookup(:sop_training_doc)}?format=partial")).body
	}
end