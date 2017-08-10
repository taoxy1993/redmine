namespace :vpn do
  desc "Check vpn account is resumed or expired"

=begin
检测VPN账户是否续签证书
=end
  task :renewal_cert => :environment do
    VpnAccount.renewal_cert
  end

=begin
检测VPN账户是否过期，删除已过期账户
=end
  task :destory_expire_cert => :environment do
    VpnAccount.destory_expire_cert
  end

end