class PubliclibController < ApplicationController
  unloadable
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper


  def index
    sort_init 'releasedate' , 'asc'
    sort_update %w(releasedate releaseversion releasenote)
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    
    @publiclib = Publiclib.find(:all,:conditions=>"project_id = '#{@identifier.id}'")    
    #@publiclib = Publiclib.find(:all)
  end
  
  private
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id]) 
  end
end
