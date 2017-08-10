require 'redmine'

Redmine::Plugin.register :redmine_vpn_ftp do
  name 'Redmine Vpn Ftp plugin'
  author '方亮'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # 添加FTP&VPN管理到admin_menu
  menu :admin_menu, 'FTP&VPN',  {:controller => 'ftp_all', :action => 'index'}, :html => {:class => 'icon icon-add'}, :caption => 'FTP&VPN管理'
  # 添加FTP&VPN管理到top_menu
  menu :top_menu, 'FTP&VPN',  {:controller => 'ftp_all', :action => 'index'},  :caption => 'FTP&VPN管理', :if => Proc.new { User.current.admin?}

end