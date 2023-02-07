get '/alert_center/?' do

    testAlerts = ["Alert One", "Alert Two", "Alert Three"]

    erb :alert_center, :layout => :fixed, :locals => {
        :generalAlerts => testAlerts,
        :woodShopAlerts => testAlerts,
        :metalShopAlerts => testAlerts,
        :digitalFabricationAlerts => testAlerts,
        :artAlerts => testAlerts
    }

end

post '/alert_center/?' do

    testAlerts = ["Alert One", "Alert Two", "Alert Three"]

    erb :alert_center, :layout => :fixed, :locals => {
        :generalAlerts => testAlerts,
        :woodShopAlerts => testAlerts,
        :metalShopAlerts => testAlerts,
        :digitalFabricationAlerts => testAlerts,
        :artAlerts => testAlerts
    }

end