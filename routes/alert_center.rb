require 'models/alert'
require 'models/alert_signup'

get '/alert_center/:user_id/?' do

    # if AlertSignup.all.where(user: ) is nil
    #     userAlerts = AlertSignup.create(user: , alert: nil)

    generalAlerts = Alert.all.where(category_id: 1).to_a
	generalAlerts.sort_by! {|generalAlerts| generalAlerts.name.downcase + generalAlerts.description.downcase}

    woodShopAlerts = Alert.all.where(category_id: 2).to_a
	woodShopAlerts.sort_by! {|woodShopAlerts| woodShopAlerts.name.downcase + woodShopAlerts.description.downcase}

    metalShopAlerts = Alert.all.where(category_id: 3).to_a
	metalShopAlerts.sort_by! {|metalShopAlerts| metalShopAlerts.name.downcase + metalShopAlerts.description.downcase}

    digitalFabricationAlerts = Alert.all.where(category_id: 4).to_a
	generalAlerts.sort_by! {|digitalFabricationAlerts| digitalFabricationAlerts.name.downcase + digitalFabricationAlerts.description.downcase}

    artAlerts = Alert.all.where(category_id: 5).to_a
	artAlerts.sort_by! {|artAlerts| artAlerts.name.downcase + artAlerts.description.downcase}

    erb :alert_center, :layout => :fixed, :locals => {
        :generalAlerts => generalAlerts,
        :woodShopAlerts => woodShopAlerts,
        :metalShopAlerts => metalShopAlerts,
        :digitalFabricationAlerts => digitalFabricationAlerts,
        :artAlerts => artAlerts
    }

end

post '/alert_center/:user_id/?' do

    # userAlerts = AlertSignup.find_by(user:)
    # userAlerts.alert = params.value
    # userAlerts.save

    redirect '/home/'

end