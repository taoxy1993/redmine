require 'redmine'

Redmine::Plugin.register :redmine_trunk do
  name 'Redmine Trunk plugin'
  author '李鹏'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :project_menu, :trunk, { :controller => 'trunk', :action => 'index' }, :caption => '分支划分', :after => :activity, :param => :id

  permission :view_trunk, :trunk => [:index,:new]
  permission :svn_freeze_or_unfreeze, :trunk => [:freeze, :unfreeze]
end
