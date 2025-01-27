require 'net/http'

get '/training-documents/?' do
	not_found if SS_ID != 1

	@breadcrumbs << {:text => 'Training Documents'}
	erb :training_documents, :layout => :fixed
end

def fetch_final_content(uri)
	url = URI.parse(uri)
	redirect_limit = 10
	redirect_count = 0

	begin
		response = Timeout::timeout(10) { Net::HTTP.get_response(url) } # Timeout after 10 seconds
	
		# Follow redirects (if any) until we reach the final destination
		while response.is_a?(Net::HTTPRedirection)
			redirect_count += 1
			raise "Too many redirects (limit: #{redirect_limit})" if redirect_count > redirect_limit

			url = URI.parse(response['location'])
			response = Net::HTTP.get_response(url)
		end

		# Handle 404 or other HTTP error responses
		case response
		when Net::HTTPSuccess
			response.body
		when Net::HTTPNotFound
			raise "Page not found (404)"
		else
			raise "HTTP error: #{response.code} #{response.message}"
		end
	rescue Timeout::Error
		raise "Request timed out"
	rescue => e
		raise "Failed to fetch content: #{e.message}"
	end
end


get '/training-documents/sop/?' do
	not_found if SS_ID != 1

	@breadcrumbs << { :text => 'Training Documents', :href => '/training-documents' }
	@breadcrumbs << { :text => 'SOP' }

	begin
		content = fetch_final_content("https://innovationstudio.unl.edu#{drupal_link_lookup(:sop_training_doc)}?format=partial")
	rescue => e
		# Handle CMS failure gracefully (e.g., log error, show custom error message)
		logger.error "Error fetching content: #{e.message}" # Logging the error

		content = 'Error getting the SOP traning documents'
	end

	erb :sop_training_document, :layout => :fixed, :locals => {
		:content => content
	}
end