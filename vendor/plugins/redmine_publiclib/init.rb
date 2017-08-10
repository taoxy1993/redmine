require 'redmine'

Redmine::Plugin.register :redmine_publiclib do
  name 'Redmine Publiclib plugin'
  author '李鹏'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  menu :project_menu, :'发行库', { :controller => 'publiclib', :action => 'index' }, :caption => '发行库', :after => :activity, :param => :id
  
  project_module :'发行库' do
    permission :publiclib, :publiclib => [:index]
  end
  
end
