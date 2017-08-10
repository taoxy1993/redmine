require 'redmine'

Redmine::Plugin.register :redmine_svnmanage do
  name 'Redmine Svnmanage plugin'
  author '李鹏'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  menu :project_menu, :svnmanage, { :controller => 'svnmanage', :action => 'index' }, :caption => '权限管理', :after => :activity, :param => :id
  
  permission :view_svnmanage, :svnmanage => [:index]
  permission :view_addmanage, :svnmanage => [:new,:allocation,:destroy]
  
end
