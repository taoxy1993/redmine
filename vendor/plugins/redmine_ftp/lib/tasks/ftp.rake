namespace :ftp do
  desc "Check ftp account is expired"

=begin
检测FTP账户是否过期，删除已过期账户
=end
  task :destory_expire_accounts => :environment do
    FtpAccount.destory_expire_accounts
  end

end