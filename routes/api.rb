require 'models/announcements'

get '/api/announcements/?' do
    announcements = Announcements.where(status: true).order(:id).map do |announcement|
        {
            header: announcement.header.to_s,
            body: announcement.text.to_s
        }
    end

    content_type :json
    {
        has_announcement: announcements.any?,
        announcements: announcements
    }.to_json
end