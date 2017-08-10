require 'redmine'

Redmine::Plugin.register :redmine_vpn do
  name 'Redmine Vpn plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # 添加VPN&VPN管理到admin_menu
  menu :admin_menu, 'VPN',  {:controller => 'vpn_accounts', :action => 'index'}, :html => {:class => 'icon icon-edit'}, :caption => 'VPN管理'
  # 添加VPN&VPN管理到top_menu
  menu :top_menu, 'VPN',  {:controller => 'vpn_accounts', :action => 'index'},  :caption => 'VPN管理', :if => Proc.new { User.current.admin?}

  permission 'VPN Manager', :vpn_accounts => [:index]
end
