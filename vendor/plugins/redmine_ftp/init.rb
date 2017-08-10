require 'redmine'

Redmine::Plugin.register :redmine_ftp do
  name 'Redmine Ftp plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # 添加FTP&VPN管理到admin_menu
  menu :admin_menu, 'FTP',  {:controller => 'ftp_accounts', :action => 'index'}, :html => {:class => 'icon icon-edit'}, :caption => 'FTP管理'
  # 添加FTP&VPN管理到top_menu
  menu :top_menu, 'FTP',  {:controller => 'ftp_accounts', :action => 'index'},  :caption => 'FTP管理', :if => Proc.new { User.current.admin?}

  permission 'FTP Manager', :ftp_accounts => [:index]
end
