namespace :vpnftpcheck do
  desc "Check vpn and ftp"

=begin
task for check ftp
=end
  task :ftpcheck => :environment do

    # 检测FTP账户，删除已过期账户
    Ftp_manager.is_expire

  end

=begin
task for check vpn
=end
  task :vpncheck => :environment do

    # 检查vpn证书在到期前3天是否需要自动续签
    Vpn_manager.is_resumed

    # 检查vpn证书是否过期，删除过期vpn证书
    Vpn_manager.is_abandoned

  end
end