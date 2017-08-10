require 'redmine'

Redmine::Plugin.register :redmine_departments do
  name 'Redmine Departments plugin'
  author 'yuzhili'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :admin_menu, :department,  {:controller => 'departments', :action => 'index'}, :html => {:class => 'groups'}, :caption => '部门', :if => Proc.new { User.current.admin?}
end
