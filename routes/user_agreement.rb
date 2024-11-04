# require 'models/event'
# require 'models/event_signup'
# require 'models/emergency_contact'
# require 'classes/emailer'
# require 'recaptcha'
require 'erb'
require 'json'
require 'net/http'
require 'models/user'

# Recaptcha.configure do |config|
# 	config.site_key = CONFIG['reCaptcha']['site_key']
# 	config.secret_key = CONFIG['reCaptcha']['secret_key']
# end

# include Recaptcha::Adapters::ControllerMethods
# include Recaptcha::Adapters::ViewMethods

get '/engineering_garage/user_agreement/?' do
    require_login
    @breadcrumbs << {:text => 'Agreement Renewal'}
	
    erb :'/engineering_garage/user_agreement', :layout => :fixed
end

post '/engineering_garage/user_agreement/?' do
  
    # if !verify_recaptcha
    #     flash(:alert, 'Google Recaptcha Verification Failed', 'Please try again.')
    #     session[:form_data] = params
    #     redirect back
    # end
    @user.set_user_agreement_expiration_date(Date.today.next_year)

	redirect '/home/'

end

# # Helper method to check if required params are present
# helpers do
#   def params_valid?
#     required_params = %w[weapon-agreement cleaning-agreement priviledge-agreement question-agreement active-cleaning-agreement ppe-agreement certification-agreement report-agreement]
#     required_params.all? { |param| params[param] == 'on' }
#   end
# end



# #copied from new_members.rb
# def fetch_final_content(uri)
# 	url = URI.parse(uri)
	
# 	begin
# 		response = Timeout::timeout(10) { Net::HTTP.get_response(url) } # Timeout after 10 seconds
	
# 		# Follow redirects (if any) until we reach the final destination
# 		while response.is_a?(Net::HTTPRedirection)
# 			url = URI.parse(response['location'])
# 			response = Net::HTTP.get_response(url)
# 		end

# 		# Handle 404 or other HTTP error responses
# 		case response
# 		when Net::HTTPSuccess
# 			response.body
# 		when Net::HTTPNotFound
# 			raise "Page not found (404)"
# 		else
# 			raise "HTTP error: #{response.code} #{response.message}"
# 		end
# 	rescue Timeout::Error
# 		raise "Request timed out"
# 	rescue => e
# 		raise "Failed to fetch content: #{e.message}"
# 	end
# end

# def valid_json?(string)
# 	!!JSON.parse(string)
# rescue JSON::ParserError
# 	false
# end


# def check_form_data(form_data, key)
# 	return form_data.is_a?(Hash) && form_data.key?(key)
# end

# # Code copied from Recaptcha::Adapters::ControllerMethods to resolve issue of this method being private

# def verify_recaptcha(options = {})
# 	options = {model: options} unless options.is_a? Hash
# 	return true if CONFIG['email']['site_key'].nil? || CONFIG['reCaptcha']['site_key'].empty?
# 	return true if Recaptcha.skip_env?(options[:env])

# 	model = options[:model]
# 	attribute = options.fetch(:attribute, :base)
# 	recaptcha_response = options[:response] || recaptcha_response_token(options[:action])

# 	begin
# 	  verified = if Recaptcha.invalid_response?(recaptcha_response)
# 		false
# 	  else
# 		unless options[:skip_remote_ip]
# 		  remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
# 		  options = options.merge(remote_ip: remoteip.to_s) if remoteip
# 		end

# 		success, @_recaptcha_reply =
# 		  Recaptcha.verify_via_api_call(recaptcha_response, options.merge(with_reply: true))
# 		success
# 	  end

# 	  if verified
# 		flash.delete(:recaptcha_error) if recaptcha_flash_supported? && !model
# 		true
# 	  else
# 		recaptcha_error(
# 		  model,
# 		  attribute,
# 		  options.fetch(:message) { Recaptcha::Helpers.to_error_message(:verification_failed) }
# 		)
# 		false
# 	  end
# 	rescue Timeout::Error
# 	  if Recaptcha.configuration.handle_timeouts_gracefully
# 		recaptcha_error(
# 		  model,
# 		  attribute,
# 		  options.fetch(:message) { Recaptcha::Helpers.to_error_message(:recaptcha_unreachable) }
# 		)
# 		false
# 	  else
# 		raise RecaptchaError, 'Recaptcha unreachable.'
# 	  end
# 	rescue StandardError => e
# 	  raise RecaptchaError, e.message, e.backtrace
# 	end
#   end

#   def verify_recaptcha!(options = {})
# 	verify_recaptcha(options) || raise(VerifyError)
#   end

#   def recaptcha_reply
# 	@_recaptcha_reply if defined?(@_recaptcha_reply)
#   end

#   def recaptcha_error(model, attribute, message)
# 	if model
# 	  model.errors.add(attribute, message)
# 	elsif recaptcha_flash_supported?
# 	  flash[:recaptcha_error] = message
# 	end
#   end

#   def recaptcha_flash_supported?
# 	request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
#   end

#   # Extracts response token from params. params['g-recaptcha-response-data'] for recaptcha_v3 or
#   # params['g-recaptcha-response'] for recaptcha_tags and invisible_recaptcha_tags and should
#   # either be a string or a hash with the action name(s) as keys. If it is a hash, then `action`
#   # is used as the key.
#   # @return [String] A response token if one was passed in the params; otherwise, `''`
#   def recaptcha_response_token(action = nil)
# 	response_param = params['g-recaptcha-response-data'] || params['g-recaptcha-response']
# 	response_param = response_param[action] if action && response_param.respond_to?(:key?)

# 	if response_param.is_a?(String)
# 	  response_param
# 	else
# 	  ''
# 	end
#   end
