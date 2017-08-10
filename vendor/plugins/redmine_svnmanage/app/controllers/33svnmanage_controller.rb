class SvnmanageController < ApplicationController
  unloadable
  before_filter :find_project, :authorize
  
  helper :sort
  include SortHelper

  def index
    sort_init 'svnmanage' , 'asc'
    sort_update %w(svnpath wrstatus)
     
    @user = User.find(User.current)
    login = @user.login
    
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    
    @svnmanage = Svnmanage.find(:all ,:conditions=>"login = '#{login}' and project_id = '#{project_id}'") 
    @findproject = Repository.find(:all,:conditions=>"project_id = '#{project_id}'")
  end
  
  def new 
    sort_init 'svnmanage' , 'asc'
    sort_update %w(svnpath wrstatus)
    
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    
    @belonged = User.find(User.current)
    login = @belonged.belonged
    
    @user = User.find(:all,:conditions=>"type = 'User'and  belonged = '#{login}'")
    @svnmanage = Svnmanage.find(:all,:conditions=>"project_id = '#{project_id}'")
    @member = Member.find(:all,:conditions=>"project_id = '#{project_id}'")
  end
  
  def allocation
    if params[:user]
      @login = params[:user]
      @svnmanage = Svnmanage.find(:all,:conditions=>"login = '#{@login}'")
    end
    if request.post?
      #@svnpath = Svnmanage.find_by_svnpath(params[:svnpath])
      @svnpath = Svnmanage.find(:all,:conditions => ["login = :login and svnpath = :svnpath and id = :id", params])
      if (@svnpath.count > 0)
        flash[:notice] = "授权已经被创建过！！！"
        redirect_to :controller => 'svnmanage', :action => 'allocation', :id => @project, :user =>params[:login]
      else
        @identifier = Project.find(@project)   
        project_id = @identifier.id
        
        @trunk = Trunk.find(:all,:conditions=>"project_id = '#{project_id}'")
        if(@trunk.count > 0)
          @trunk.each do |trunk|
            @a = trunk.createdate
            if(@a == "trunk")
               @b = trunk.trunk + ":/trunk"
            else
               @b = trunk.trunk + ":/branches/" + trunk.branches
            end
            break
          end
                  
          @addsvnmanage = Svnmanage.new(:pjmember=>@b,:project_id => project_id,:login => params[:login],:svnpath => params[:svnpath],:wrstatus =>params[:wrstatus])
          if @addsvnmanage.save
            set_authz
            flash[:notice] = "创建成功！"
            redirect_to :controller => 'svnmanage', :action => 'allocation', :id => @project, :user =>params[:login]
          end
         else
            flash[:notice] = "请创建工程！！！"
            redirect_to :controller => 'trunk', :action => 'index', :id => @project
         end
      end
    end
  end
  
  def destroy
    @svnmanage = Svnmanage.find(:all,:conditions => ["login = :login and svnpath = :svnpath", params])
    puts @svnmanage.count
    @svnmanage.each do |svnmanage|
      svnmanage.destroy
    end
    set_authz
    flash[:notice] = "删除成功！"
    redirect_to :controller => 'svnmanage', :action => 'new', :id => @project, :user =>params[:login]
  end
  
  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id]) 
  end
  
  def set_authz
     @allsvndata = Svnmanage.find(:all)
     a = "/opt/svn/authz"
     fd = File.new(a, "w+")
     @allsvndata.each do |allsvndata|
        b = allsvndata.pjmember
        if(b == nil || b == "")
          next
        end
        if (allsvndata.svnpath == "*")
          @c = "[" + b + "]"
        else
          @c = "[" + b + "/" + allsvndata.svnpath + "]"
        end
        puts @c
        d = allsvndata.login + "=" + allsvndata.wrstatus
        puts d             
        fd.puts @c
        fd.puts d
      end
      fd.close
  end
 
end
