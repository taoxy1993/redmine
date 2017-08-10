require 'redmine'

Redmine::Plugin.register :redmine_category do
  name 'Redmine Category plugin'
  author 'yuzhili'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # menu :top_menu, :categorys, { :controller => 'categorys', :action => 'index' }, :caption => '项目分类'

  permission 'Project Category', :categorys => [:index]
end