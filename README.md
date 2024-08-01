# UNL Reservations

UNL reservation system for schedule resources, classes, etc.

## Quick Tutorial

1. Service spaces refer to different silos of the University that will utilize resources. E.g. the math department, the Honors program, or University Communication.
2. Super Admins of a space can do anything, including giving others access and privileges to the space.
3. Resources are created, and then may be reserved by anyone who has the User Access privilege in the space. 
4. Events *may* include a resource reservation but do not have to.
5. Admins with the right privilege can set the *hours* of the space, which indicate when reservations can be made.
6. The agenda is a quick overview of the day for Admins to look at.

## Installation Local

0. Run `xcode-select --install`. Congratulations, you have saved yourself 5000 insanity points.
1. Get the right ruby on your machine. UNL Resource Scheduler currently runs on Ruby 2.6.5. Get RVM on your machine with `\curl -sSL https://get.rvm.io | bash`.
2. Now using RVM, install the ruby with `rvm install 2.6.5`.
3. You probably do not have the `bundler` gem. Check with `bundle`. If not, install it with `gem install bundler`.
4. In the project root, install the gems using `bundle install`.
5. Create a mysql database you'd like to use, you can typically use one on your computer. `brew install mysql` if necessary. 
6. `config/config.json` is a committed file, and a template for the configuration. Create a copy in the same directoy named `server.json` and edit it to match your database. You will also need to include your site keys for google reCaptcha which can be generated at https://www.google.com/recaptcha/ for the V2 checkbox.
7. Your database is currently blank. Install database schema by running `./data/db_2024_08_01.sql` and any updates greater than `0006`.
8. Install the WDN Framework into the `public/wdn` directory...see [WDN Documentation](http://wdn.unl.edu/documentation).
9. Start the server by going to the root directory and doing `bundle exec shotgun -o 0.0.0.0 -p 9393`. This launches the server on localhost port 9393, listening everywhere (you can use your iimlemburg.unl.edu or whichever), and the server will automatically update to new code. If you add gems to the bundle, you will need to re-execute this command.
10. Navigate to `localhost:9393/` or similar and begin!

### Less

I couldn't get Guard to work for me locally so I also added a npm version of less complication

The traditional way to compile less `bundle exec guard`

The NPM way to compile less

1. Run `npm ci` to install less
2. Run `npm run less` to compile less

## Installation on server

1. Run `sudo -u {user} -s` run commands as a user and navigate to your project's root
2. Run `cp ./config/config.json ./config/server.json` to copy config file and customize it to your environment
3. Run `ln -s {path to WDN Templates} {path to project root}/public/wdn` to symlink WDN Templates to your project
4. Run `/bin/bundler install` to install dependencies
5. Install database schema by running `./data/db_2024_08_01.sql` and any updates greater than `0006`
6. You will need to get a service running for unicorn using systemd
    1. Run `cp ./startup.sh.sample ./startup.sh` and customize file for your domain and sock
    2. Run `cp ./unicorn.rb.sample ./unicorn.rb` and customize file for your domain and sock
    3. Run `mkdir -p ~/.config/systemd/user` to set up systemd user directory
    4. Run `cp ./unicorn.service.sample ~/.config/systemd/user/unicorn.service` and customize file for your domain and sock
7. Run `systemctl --user start unicorn` to start the service
8. Run `systemctl --user enable unicorn` to start the service on boot

## Deploying Updates on Staging

1. Run these commands to restart the unicorn server.

    ``` bash
    cat innovationstudio-manager-test.pid
    sudo -u innovationstudio-test kill -9 [replace with PID from first command]
    sudo -u innovationstudio-test ./startup.sh
    ```

2. After restarting the unicorn server make sure that there are only two scheduler processes running. The scheduler processes handle sending out automated emails on a daily basis. There should be one for the staging environment and one for the production environment. If more than 2 processes are running then users will receive duplicate emails. Run the command below to check if multiple processes are running. You should only get 2 process IDs back.

    ``` bash
    pgrep ruby
    ```

3. If you get more than 2 processes IDs then you need to check which users started each process. There should be one process started by the innovationstudio-test user(the staging user) and one process started by the innovationstudio user. You can check the user of a process with this command where pid is the process ID.

    ``` bash
    ps -o user= -p pid
    ```

4. Once you determine which processes are extra (if any) then kill them with this command.

    ``` bash
    sudo -u innovationstudio kill -9 pid
    ```

## Deploying Updates on Production

1. Run these commands to restart the unicorn server.

    ``` bash
    sudo -u innovationstudio -s -H
    systemctl --user restart unicorn
    ```

2. If the production environment fails to start after executing those commands then an error must have occurred. You can view the error log with the following command. This command will print the last 50 lines of the error log:

    ``` bash
    cat error.log | tail -n 50
    ```

3. If the error log happens to say that the unicorn server cannot start because the process already exists (even though the server is still down) you can run the following commands to determine the process ID and to kill the processe. After killing the existing process and trying to restart the server you should get a more helpful error message in the error log if the server still fails to start.
Use this command to find the process ID. The process you're looking for should have this in the command column:

    ``` bash
    unicorn master -l /run/httpd-local/innovationstudio.sock -E production -c /var/www/html/innovationstudio-manager.unl.edu/unicorn.rb
    ```

    ``` bash
    ps aux
    ```

    Use this command to kill the process ID

    ``` bash
    sudo -u innovationstudio kill -9 pid
    ```

## CRON

``` text
0 12 * * * ruby ././scripts/email_expiring_users.rb
0 12 * * * ruby ././scripts/email_unconfirmed_trainers.rb
0 22 * * * ruby ././scripts/email_expiring_users_vehicle_update.rb

#@reboot /var/www/html/innovationstudio-manager.unl.edu/startup.sh
```
