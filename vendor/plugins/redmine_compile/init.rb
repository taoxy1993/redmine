require 'redmine'

Redmine::Plugin.register :redmine_compile do
  name 'Redmine Compile plugin'
  author '李鹏'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  menu :project_menu, :compile, { :controller => 'compile', :action => 'index' }, :caption => '编译', :after => :activity, :param => :id
  
  project_module :compile do
    permission :view_compile, :compile => [:index,:new,:destroy,:docompile,:add,:choose,:compileoption,:canclecompile]
  end
  
end
