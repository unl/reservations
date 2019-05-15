require 'models/maker_request'
require 'securerandom'

get '/maker_request/?' do
	@breadcrumbs << {:text => 'Maker Request'}

	erb :maker_request, :layout => :fixed, :locals => {
	    maker_request: nil
	}
end

get '/maker_request/:marker_request_uuid/edit/?' do
   	@breadcrumbs << {:text => 'Maker Request'}

    maker_request = Maker_Request.find_by(uuid: :marker_request_uuid)

   	erb :maker_request, :layout => :fixed, :locals => {
   	    maker_request: maker_request
   	}
end

post '/maker_request/?' do
    puts params.inspect
	# check that username is not taken
	if params[:category_id].nil?
		flash(:alert, 'Category', 'Please select a category.')
		redirect back
	end

	maker_request = Maker_Request.new(params)
	maker_request.uuid = SecureRandom.uuid
	maker_request.status_id = Maker_Request::STATUS_OPEN
	maker_request.save

	flash :success, 'Maker Request Created', 'Your maker request has been created.'

    redirect '/maker_request/'
end

get '/maker_request/list/?' do
   	@breadcrumbs << {:text => 'Maker Request List'}
	require_login
	check_membership

    maker_requests = Maker_Request.find_by(status_id: Maker_Request::STATUS_OPEN)
    puts maker_requests.inspect
   	erb :maker_request_list, :layout => :fixed, :locals => {
   	    maker_requests: maker_requests
   	}
end

