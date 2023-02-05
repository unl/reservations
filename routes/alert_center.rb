get '/alert_center/?' do

    totals = ["hello", "world"]

    erb :alert_center, :layout => :fixed, :locals => {
        :totals => totals
    }

end