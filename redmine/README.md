How to build Redmine with KUSANAGI

1. In advance checkout the redmine and below.
2. If using tarball, download the file from https: // github.com / redmine / redmine / archive / 3.4.6.zip.
3. When using Vagrant, change Vagrant setting (memory, used IP address etc.) accordingly.
4. If you have already done kusanagi init, comment out the relevant part of setup_redmine.sh.
5. For Vagrant, perform vagrant up.
6. When setting up from the KUSANAGI environment, place setup_redmine.sh, ar_innodb_row_format.rb etc, and launch setup_redmine.sh with sh.