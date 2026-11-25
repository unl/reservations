require 'models/announcements'

before '/admin/announcements/edit*' do
  unless has_permission?(Permission::SUPER_USER)
    raise Sinatra::NotFound
  end
end

get '/admin/announcements/edit/:id/?' do
  require_login

  @breadcrumbs << {:text => 'Admin', :href => '/admin/'}
	@breadcrumbs << {:text => 'Announcements', :href => '/admin/announcements/'}
  @breadcrumbs << {:text => 'Edit announcement'}

  announcement = Announcements.find(params[:id])

  erb :'admin/announcement_edit', :layout => :fixed_61, :locals => {
    :announcement => announcement,
  }
end

post '/admin/announcements/edit/:id/?' do
  require_login

  announcement = Announcements.find(params[:id])
  announcement.text = params[:text]
  if announcement.text.empty?
    flash :error, 'Error', 'Please enter the text for the announcement'
    redirect back
  end
  announcement.header = params[:header]
  if announcement.header.empty?
    flash :error, 'Error', 'Please enter the header for the announcement'
    redirect back
  end
  announcement.status = params[:status] == '1' ? 1 : 0
  announcement.save

  flash :success, 'Success', 'Your announcement has been updated!'
  redirect '/admin/announcements/'
end

post '/admin/announcements/edit/:id/delete/?' do
  require_login

  announcement = Announcements.find(params[:id])
  announcement.destroy

  flash :success, 'Success', 'Your announcement has been deleted!'
  redirect '/admin/announcements/'
end

