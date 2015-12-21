# reservations
Room, tools, and resource reservation system. Developed in Ruby, running on Sinatra

## Starting up the server
This is documentation on how to start the server in production, local deployments might vary

1. Run `./startup.sh`

Note: The `startup.sh` script is on a cron job which will start the server on server start. Ex:
```
@reboot /absolute/path/startup.sh
```
