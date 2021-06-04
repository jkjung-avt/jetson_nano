# I found this fix from the following JetsonHacks' script
# https://github.com/jetsonhacks/installROSTX1/blob/master/installROS.sh

# This fixes the issue of wget failing with "ERROR: cannot verify XXXXX's certificate"
sudo c_rehash /etc/ssl/certs
