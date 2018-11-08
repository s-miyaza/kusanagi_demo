export KUSANAGI_PASSWORD=`mkpasswd -l 20`
export DBROOTPASS=`mkpasswd -s 0 -l 20`

export SITE_DOMAIN=redmine2.localdomain

export DBNAME=`mkpasswd -s 0 -l 10`
export DBUSER=`mkpasswd -s 0 -l 10`
export DBPASS=`mkpasswd -s 0 -l 20`
export EMAILOPTION=--no-email

yum install -y ImageMagick-devel
kusanagi init --tz tokyo --lang en --keyboard en --passwd $KUSANAGI_PASSWORD --no-phrase --dbrootpass "$DBROOTPASS" --php7 --nginx --ruby24 --dbsystem mariadb
kusanagi provision --rails --fqdn $SITE_DOMAIN --noemail --dbname $DBNAME --dbuser $DBUSER --dbpass "$DBPASS" redmine
cd /home/kusanagi
rm -rf redmine
systemctl stop nginx
echo untar redmine
# if use github, comment out under 2lines.
tar xf /tmp/redmine-3.4.6.tar.gz
mv redmine-3.4.6 redmine 
# git clone -t 3.4-stable https://github.com/redmine/redmine.git
cd redmine && chown -R kusanagi:kusanagi .
chown -R httpd:www tmp files public/plugin_assets
mkdir -m 775 log/nginx log/httpd
chown -R kusanagi:www log
chmod 775 log
echo set rails configure
cp /tmp/ar_innodb_row_format.rb config/initializers/ar_innodb_row_format.rb
echo 'config.logger = Logger.new(Rails.root.join("log",Rails.env + "-ERROR.log"), 3, 10 * 1024 * 1024)' | tee config/additional_environment.rb > /dev/null
echo 'config.logger.level = Logger::ERROR' | tee -a config/additional_environment.rb > /dev/null
cp config/configuration.yml.example config/configuration.yml
sed -e "s/database: .*$/database: $DBNAME/" -e "s/username: .*$/username: $DBUSER/" -e "s/password: .*$/password: \"$DBPASS\"/"  -e "s/encoding: .*$/encoding: utf8mb4/" config/database.yml.example config/database.yml.example | tee config/database.yml > /dev/null

echo set mysql
systemctl stop mysql
awk '{print} /innodb_thread_concurrency = 8/ {printf "innodb_file_format = Barracuda\ninnodb_file_per_table = 1\ninnodb_large_prefix = 1\n"}' /etc/my.cnf.d/server.cnf > /tmp/server.cnf
mv /tmp/server.cnf /etc/my.cnf.d/server.cnf
systemctl start mysql

echo set nginx settings
awk '/passenger_min_instances/ {print "\t\tpassenger_user httpd;\n\t\tpassenger_group www;"} /rails_env development;/ { printf "#"} /rails_env production;/ {print "\t\trails_env production;"} {print}' /etc/nginx/conf.d/redmine_http.conf | tee /etc/nginx/conf.d/redmine_http.conf > /dev/null
awk '/passenger_min_instances/ {print "\t\tpassenger_user httpd;\n\t\tpassenger_group www;"} /rails_env development;/ { printf "#"} /rails_env production;/ {print "\t\trails_env production;"} {print}' /etc/nginx/conf.d/redmine_ssl.conf | tee /etc/nginx/conf.d/redmine_ssl.conf > /dev/null
echo 'passenger_instance_registry_dir /var/run/passenger-instreg;' >> /etc/nginx/conf.d/kusanagi_rails.conf

systemctl start nginx

echo bundle install
bundle install --without development test postgresql sqlite3
rake generate_secret_token
RAILS_ENV=production rake db:migration
RAILS_ENV=production rake db:migrate
echo ja | RAILS_ENV=production rake redmine:load_default_data

find /home/kusanagi/redmine/log -name '*.log' | xargs chown httpd:www
