export KUSANAGI_PASSWORD=`mkpasswd -l 20`
export DBROOTPASS=`mkpasswd -s 0 -l 20`

export KUSANAGI_PROFILE=redmine
export SITE_DOMAIN=redmine.localdomain

export DBNAME=`mkpasswd -s 0 -l 10`
export DBUSER=`mkpasswd -s 0 -l 10`
export DBPASS=`mkpasswd -s 0 -l 20`
export EMAILOPTION=--no-email

yum install -y ImageMagick-devel
test -f /etc/kusanagi.d/profile.conf || (echo n | kusanagi init --tz tokyo --lang en --keyboard en --passwd $KUSANAGI_PASSWORD --no-phrase --dbrootpass "$DBROOTPASS" --php7 --nginx --ruby24 --dbsystem mariadb)
kusanagi provision --rails --fqdn $SITE_DOMAIN --noemail --dbname $DBNAME --dbuser $DBUSER --dbpass "$DBPASS" $KUSANAGI_PROFILE
rm -rf /home/kusanagi/$KUSANAGI_PROFILE
systemctl stop nginx
echo untar redmine
# if use github, comment out under 2lines.
cd /tmp
tar xf /tmp/redmine-3.4.6.tar.gz
mv redmine-3.4.6 /home/kusanagi/$KUSANAGI_PROFILE
# git clone -t 3.4-stable https://github.com/redmine/redmine.git
cd /home/kusanagi/$KUSANAGI_PROFILE && chown -R kusanagi:kusanagi .
chown -R httpd:www tmp files public/plugin_assets
mkdir -m 775 log/nginx log/httpd
chown -R kusanagi:www log
chmod 775 log
echo set rails configure
cp /tmp/ar_innodb_row_format.rb config/initializers/ar_innodb_row_format.rb
echo 'config.logger = Logger.new(Rails.root.join("log",Rails.env + "-ERROR.log"), 3, 10 * 1024 * 1024)' >> config/additional_environment.rb
echo 'config.logger.level = Logger::ERROR' >> config/additional_environment.rb
cp config/configuration.yml.example config/configuration.yml
sed -e "s/database: .*$/database: $DBNAME/" -e "s/username: .*$/username: $DBUSER/" -e "s/password: .*$/password: \"$DBPASS\"/"  -e "s/encoding: .*$/encoding: utf8mb4/" config/database.yml.example config/database.yml.example | tee config/database.yml > /dev/null

echo set mysql
systemctl stop mysql
awk '{print} /innodb_thread_concurrency = 8/ {printf "innodb_file_format = Barracuda\ninnodb_file_per_table = 1\ninnodb_large_prefix = 1\ninnodb_strict_mode = 1\n"}' /etc/my.cnf.d/server.cnf > /tmp/server.cnf
mv /tmp/server.cnf /etc/my.cnf.d/server.cnf
systemctl start mysql

echo set nginx settings
awk '/passenger_min_instances/ {print "\t\tpassenger_user httpd;\n\t\tpassenger_group www;"} /rails_env development;/ { printf "#"} /rails_env production;/ {print "\t\trails_env production;"} {print}' /etc/nginx/conf.d/${KUSANAGI_PROFILE}_http.conf > /tmp/${KUSANAGI_PROFILE}_http.conf && cat /tmp/${KUSANGI_PROFILE}_http.conf > /etc/nginx/conf.d/${KUSANAGI_PROFILE}_http.conf && rm /tmp/${KUSANAGI_PROFILE}_http.conf
awk '/passenger_min_instances/ {print "\t\tpassenger_user httpd;\n\t\tpassenger_group www;"} /rails_env development;/ { printf "#"} /rails_env production;/ {print "\t\trails_env production;"} {print}' /etc/nginx/conf.d/${KUSANAGI_PROFILE}_ssl.conf > /tmp/${KUSANAGI_PROFILE}_ssl.conf && cat /tmp/${KUSANGI_PROFILE}_ssl.conf > /etc/nginx/conf.d/${KUSANAGI_PROFILE}_ssl.conf && rm /tmp/${KUSANAGI_PROFILE}_ssl.conf
grep -v 'passenter_instance_registry_dir' /etc/nginx/conf.d/kusanagi_rails.conf || echo 'passenger_instance_registry_dir /var/run/passenger-instreg;' >> /etc/nginx/conf.d/kusanagi_rails.conf

systemctl start nginx

echo bundle install
bundle install --without development test postgresql sqlite3
rake generate_secret_token
RAILS_ENV=production rake db:migration
RAILS_ENV=production rake db:migrate
echo ja | RAILS_ENV=production rake redmine:load_default_data

find /home/kusanagi/redmine/log -name '*.log' | xargs chown httpd:www
