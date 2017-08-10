# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

#set :output, "/usr/local/redmine/log/cron_log.log"

# 设置工作模式，设置定时任务日志输出文件log/cron_error_log.log和log/cron_log.log
set :environment, "development"
# set :environment, "production"
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

# 定时任务，每隔{5 minutes}执行一次ftp_cron_tasks
every 5.minutes do
   rake "ftp:destory_expire_accounts"
end

# 定时任务，每隔{5 minutes}执行一次vpn_cron_tasks
every 5.minutes do
   rake "vpn:renewal_cert"
   rake "vpn:destory_expire_cert"
end

#every 1.day, :at => '5:00 pm' do
#every 1.day, :at => '00:00' do
#   rake "vpnftpcheck:ftpcheck"
#end
