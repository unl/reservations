require 'models/announcements'

get '/api/announcements/?' do
    announcement = Announcements.first

    content_type :json
    if announcement
        { has_announcement: true, header: announcement.header, body: announcement.text }.to_json
    else
        { has_announcement: false, header: "", body: "" }.to_json
    end
end