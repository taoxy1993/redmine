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
    puts project_id  
    
    @svnmanage = Svnmanage.find(:all ,:conditions=>"login = '#{login}' and project_id = '#{project_id}'") 
    @svnmanage.each do |svnmanage|
      puts svnmanage.svn_trunk
      if((svnmanage.svn_trunk == 'HEAD')||(svnmanage.svn_trunk == nil))
        trunks = Trunk.find_by_sql("select repository_name from trunks where svn_path_type = 'trunk' and project_id = '#{project_id}'")
        temp = trunks[0]
        p = "http://mcv.inspur.com/svn/"+ temp.repository_name + "/trunk/"
        svnmanage.svn_trunk=p
      else
        brachesname = svnmanage.svn_trunk
        trunks = Trunk.find_by_sql("select repository_name from trunks where branches = '#{brachesname}' and project_id = '#{project_id}'")
        temp = trunks[0]
        p = "http://mcv.inspur.com/svn/"+ temp.repository_name + "/branches/" + svnmanage.svn_trunk
        svnmanage.svn_trunk=p
      end
    end
  end
  
  def new 
    sort_init 'svnmanage' , 'asc'
    sort_update %w(svnpath wrstatus)
      
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    
    @belonged = User.find(User.current)
    @login11 = @belonged.login
    
    puts @login11
       
    #@user = User.find(:all,:conditions=>"type = 'User'and  belonged = '#{login}'")
    @user = User.find(:all)
    @svnmanage = Svnmanage.find(:all,:conditions=>"project_id = '#{project_id}'")
    @svnmanage.each do |svnmanage|
      if((svnmanage.svn_trunk == 'HEAD')||(svnmanage.svn_trunk == nil))
        svnmanage.svn_trunk="主线"
      else
          
      end
    end
    @member = Member.find(:all,:conditions=>"project_id = '#{project_id}'")
    
    @user_roles = MemberRole.find(:all)
  end
  
  def allocation
    sort_init 'svnmanage' , 'asc'
    sort_update %w(svnpath wrstatus)
    
    if params[:user]
      @login = params[:user]
      @identifier = Project.find(@project)   
      project_id = @identifier.id
      @svnmanage = Svnmanage.find(:all,:conditions=>"login = '#{@login}' and project_id = '#{project_id}'")
      @svnmanage.each do |svnmanage|
        if((svnmanage.svn_trunk == 'HEAD')||(svnmanage.svn_trunk == nil))
          svnmanage.svn_trunk="主线"
        end
      end
      #@trunk = Trunk.find(:all,:conditions=> "svn_path_type = 'trunk' and project_id = '#{project_id}'")
      @trunk = Trunk.find(:all,:conditions=> "project_id = '#{project_id}'")
      #if (@trunk.count == 0)
         #flash[:notice] = "请先进行分支划分，将代码树和工程关联后再分配权限！！！"
         #redirect_to :controller => 'trunk', :action => 'index', :id => @project
      #end
      @tag = Trunk.find(:all,:conditions=> "project_id = '#{project_id}'")
      @tag.each do |tag|
        if(tag.svn_path_type == 'trunk')
          tag.branches='HEAD'
        end
      end
    end
    if request.post?
      usetrunk = params[:repository_name]
      usebranches = params[:branches]
      uselogin = params[:login]
      usesvnpath = params[:svnpath]
      if(usebranches == "HEAD")
        mysvnpath = usetrunk + ":/trunk"
      else
        mysvnpath = usetrunk + ":/branches/" + usebranches
      end
      puts mysvnpath
      @svnpath = Svnmanage.find(:all,:conditions=> "login = '#{uselogin}' and svnpath = '#{usesvnpath}' and permission_path = '#{mysvnpath}'")
      #@svnpath = Svnmanage.find(:all,:conditions => ["login = :login and svnpath = :svnpath and id = :id", params])
      if (@svnpath.count > 0)
        flash[:notice] = "授权已经被创建过！！！"
        redirect_to :controller => 'svnmanage', :action => 'allocation', :id => @project, :user =>params[:login]
      else
        @identifier = Project.find(@project)   
        project_id = @identifier.id
        
        @trunk = Trunk.find(:all,:conditions=>"project_id = '#{project_id}'")
        if(@trunk.count > 0)
          @addsvnmanage = Svnmanage.new(:permission_path=>mysvnpath,:project_id => project_id,:login => uselogin,:svnpath => usesvnpath,:wrstatus =>params[:wrstatus],:svn_trunk => usebranches)
          if @addsvnmanage.save
            write_authz
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
    a = params[:trunkpath]
    if((a == "主线")||(a == nil) ||(a == "HEAD"))
      b = params[:id] + ":/trunk"
    else
      b = params[:id] + ":/branches/" + a
    end
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    
    @svnmanage = Svnmanage.find(:all,:conditions => ["login = :login and svnpath = :svnpath and project_id = '#{project_id}' and permission_path = '#{b}'", params])
    puts @svnmanage.count
    @svnmanage.each do |svnmanage|
      svnmanage.destroy
    end
    write_authz
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
        b = allsvndata.permission_path
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

  # flock file
  def flock_file(file, mode)
    success = file.flock(mode)
    if success
      begin
        yield file
      ensure
        file.flock(File::LOCK_UN)
      end
    end
    return success
  end

  # 用户SVN路径权限写入/opt/svn/authz文件
  def write_authz
    puts "-----------------write authz start-------------------"
    @svnmanages = Svnmanage.find(:all)
    open('/opt/svn/authz', 'w+') do |file|
      flock_file(file, File::LOCK_EX) do |f|
        sleep 3 #等待3秒
        @svnmanages.each do |svnmanage|
          permission_path = get_permission_path(svnmanage)
          user_wr_permission = get_user_wr_permission(svnmanage)

          f.puts permission_path
          f.puts user_wr_permission
        end
      end
      file.close
    end
    puts "-----------------write authz end-------------------"
  end

  # 获取SVN权限路径，用于写入authz文件
  def get_permission_path(svnmanage)
    permission_path = svnmanage.permission_path
    if(permission_path == nil || permission_path == "")
      permission_path_out = ""
    else
      if (svnmanage.svnpath == "*")
        permission_path_out = "[" + permission_path + "]"
      else
        permission_path_out = "[" + permission_path + "/" + svnmanage.svnpath + "]"
      end
    end
  end

  # 获取用户读写权限，用于写入authz文件
  def get_user_wr_permission(svnmanage)
    permission_path = svnmanage.permission_path
    if(permission_path == nil || permission_path == "")
      user_wr_permission = ""
    else
      permission_path_arr = permission_path.gsub(':', '').split('/')
      wr_permission = ''
      if permission_path_arr.length >= 2
        if permission_path_arr[1].eql?('trunk')
          @trunk = Trunk.find(:first, :conditions=> "repository_name = '#{permission_path_arr[0]}' and svn_path_type = 'trunk'")
          wr_permission = @trunk.status == Trunk::STATUS_FROZEN ? 'r' : svnmanage.wrstatus if !@trunk.nil?
        end

        if permission_path_arr[1].eql?('branches')
          @trunk = Trunk.find(:first, :conditions=> "repository_name = '#{permission_path_arr[0]}' and svn_path_type = 'brahches' and branches = '#{permission_path_arr[2]}'")
          wr_permission = @trunk.status == Trunk::STATUS_FROZEN ? 'r' : svnmanage.wrstatus if !@trunk.nil?
        end

        if permission_path_arr[1].eql?('tags')
          @trunk = Trunk.find(:first, :conditions=> "repository_name = '#{permission_path_arr[0]}' and svn_path_type = 'tags' and branches = '#{permission_path_arr[2]}'")
          wr_permission = @trunk.status == Trunk::STATUS_FROZEN ? 'r' : svnmanage.wrstatus if !@trunk.nil?
        end

      else
        @trunk = Trunk.find(:first, :conditions=> "repository_name = '#{permission_path_arr[0]}' and svn_path_type = 'trunk'")
        wr_permission = @trunk.status == Trunk::STATUS_FROZEN ? 'r' : svnmanage.wrstatus if !@trunk.nil?
      end

      user_wr_permission = svnmanage.login + "=" + wr_permission
    end
  end
 
end
