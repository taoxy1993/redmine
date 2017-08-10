class TrunkController < ApplicationController
  unloadable
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper

  def index
     sort_init 'trunk' , 'asc'
     sort_update %w(repository_name branches creater status)
     @project_use = Project.find(@project)  
     project_id = @project_use.id
     @trunk = Trunk.find(:all,:conditions=> "project_id = '#{project_id}'")
  end

  def new
    @project_use = Project.find(@project)   
    @show_name=@project_use.identifier
    project_id = @project_use.id
    #@trunk = Trunk.find(:all,:conditions=> "svn_path_type = 'trunk' and project_id = '#{project_id}'")
    @trunk = Trunk.find(:all,:conditions => "svn_path_type = 'trunk'")
    @tag = Trunk.find(:all,:conditions=> "project_id = '#{project_id}'")
    @tag.each do |tag|
      if(tag.svn_path_type == 'trunk')
          tag.branches='HEAD'
      end
    end
    if request.post?
      puts params[:repository_name]
      a = params[:localpath]
      puts a
      @svnroot = "http://mcv.inspur.com/svn/"
      #"http://mcv.inspur.com/svn/"
      @identifier = Project.find(@project)   
      project_id = @identifier.id
      
      @user = User.find(User.current)
      login = @user.login
      
      #@findcreate = Trunk.find(:all,:conditions=> "project_id = '#{project_id}'")
      #if(@findcreate.count > 0)
        #flash[:notice] = "该项目已经创建过工程！！！"
        #redirect_to :controller => 'trunk', :action => 'index', :id => @project
        #return
      #end
       if (a != ""&&params[:repository_name]!=""&&params[:description]!=""&&a!= nil&&params[:repository_name] != nil&&params[:description]!=nil)
        b = params[:repository_name]
        @findtrunk = Trunk.find(:all,:conditions=> "repository_name = '#{b}'")
        puts @findtrunk.count
        if(@findtrunk.count > 0)
          flash[:notice] = "该名字的主线已经创建过！！！"
          redirect_to :controller => 'trunk', :action => 'index', :id => @project
        else
          permission_path = b + ":/"
           
          c = params[:description]
          d = @svnroot + b
          @e = "请本机上执行svn import " + a +" " + d + "/trunk -m " + "\""+ c + "\"" + " --username " + login
          f = "svnadmin create " + "/opt/svn/" + b 
        
          puts f
          puts @e
          system f
            
          command = "chown -R apache:apache " + "/opt/svn/" + b
          puts command
          system command
          command = "chown -R daemon " + "/opt/svn/" + b
          puts command
          system command
    
          command = "svn mkdir " + @svnroot + b + "/trunk" + " -m " + "\""+ "mkdir" + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
          system command
          puts command
          
          command = "svn mkdir " + @svnroot + b + "/tags" + " -m " + "\""+ "mkdir" + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
          system command
          puts command
          
          command = "svn mkdir " + @svnroot + b + "/branches" + " -m " + "\""+ "mkdir" + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
          system command
          puts command     
          #system @e

          @trunk = Trunk.new(:project_id => project_id,:creater =>login,:repository_name => b,:svn_path_type=> "trunk")

          if @trunk.save
            @addsvnmanage = Svnmanage.new(:permission_path => permission_path,:project_id => project_id,:login =>login,:svnpath =>"*",:wrstatus =>"rw")
            if @addsvnmanage.save
              write_authz
            end
            if(login != "supurman")
              @addsvnmanage1 = Svnmanage.new(:permission_path => permission_path,:project_id => project_id,:login =>"supurman",:svnpath =>"*",:wrstatus =>"rw")
              if @addsvnmanage1.save
                write_authz
              end
            end
            flash[:notice] = @e
            redirect_to :controller => 'trunk', :action => 'index', :id => @project
          end 
        end
     else 
       if(params[:tag]!= ""&&params[:tag]!= nil )
          b = params[:newtrunk] 
          c = params[:tag]          
          d = params[:tag_description]
          e = params[:newbranches]

          # 判断选择的主线是否被冻结
          @chosen_trunk = Trunk.find(:first, :conditions=> "repository_name = '#{b}' and svn_path_type = 'trunk'")
          if @chosen_trunk.frozen?
            flash[:error] = "创建标签失败，选择的主线#{b}已经被冻结，解冻后才能创建标签！！！"
            return
          end
          # 判断选择的分支是否被冻结
          @chosen_branches = Trunk.find(:first, :conditions=> "repository_name = '#{b}' and svn_path_type = 'brahches' and branches = '#{e}'")
          if @chosen_branches.frozen?
            flash[:error] = "创建标签失败，选择的分支#{e}已经被冻结，解冻后才能创建标签！！！"
            return
          end

          if(b!= ""&&c != ""&&d != ""&&e!=""&&b!=nil&&c!=nil&&d!=nil&&e!=nil)
              if(e == "HEAD")
                @findtrunk = Trunk.find(:all,:conditions=> "repository_name = '#{b}' and tags = '#{c}'")
                if(@findtrunk.count > 0)
                  flash[:notice] = "该名字的标签已经创建过！！！"
                  return
                end
                @svncommand = "svn copy " + @svnroot + b + "/trunk " +  @svnroot + b + "/tags/" + c +" -m " + "\""+ d + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
              else
                @findtrunk = Trunk.find(:all,:conditions=> "repository_name = '#{b}' and tags = '#{c}' and branches = '#{e}'")
                if(@findtrunk.count > 0)
                  flash[:notice] = "该名字的标签已经创建过！！！"
                  return
                end
                @svncommand = "svn copy " + @svnroot + b + "/branches/" + e + " " +  @svnroot + b + "/tags/" + c +" -m " + "\""+ d + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
              end
              
              @trunk = Trunk.new(:project_id => project_id,:creater =>login,:repository_name => b,:branches => e,:svn_path_type=> "tags",:tags => c)
              
              puts @svncommand
              system @svncommand
              if @trunk.save
                flash[:notice] = "标签创建成功！！！"
                redirect_to :controller => 'trunk', :action => 'index', :id => @project     
              end       
          else
            flash[:notice] = "请输入参数！！！"
            redirect_to :controller => 'trunk', :action => 'new', :id => @project
          end
       else
          b = params[:usetrunk] 
          puts b
          c = params[:buildbranches]          
          d = params[:builddescription]
          o = params[:usebranches]

          # 判断选择的主线是否被冻结
          @chosen_trunk = Trunk.find(:first, :conditions=> "repository_name = '#{b}' and svn_path_type = 'trunk'")
          if @chosen_trunk.frozen?
            flash[:error] = "创建分支失败，选择的主线#{b}已经被冻结，解冻后才能创建分支！！！"
            return
          end
          # 判断选择的分支是否被冻结
          @chosen_branches = Trunk.find(:first, :conditions=> "repository_name = '#{b}' and svn_path_type = 'brahches' and branches = '#{o}'")
          if @chosen_branches.frozen?
            flash[:error] = "创建分支失败，选择的分支#{o}已经被冻结，解冻后才能创建分支！！！"
            return
          end

          if(b!= ""&&c != ""&&d != ""&&o!=""&&b!=nil&&c!=nil&&d!=nil&&o!=nil)
            if(o == "HEAD")
              e = "svn copy " + @svnroot + b + "/trunk " +  @svnroot + b + "/branches/" + c +" -m " + "\""+ d + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
            else
              e = "svn copy " + @svnroot + b + "/branches/" + o + " " +  @svnroot + b + "/branches/" + c +" -m " + "\""+ d + "\"" + " --username supurman" + " --password Inspur_20120703_mEDIAld"
            end
            puts e
            @findtrunk = Trunk.find(:all,:conditions=> "repository_name = '#{b}' and branches = '#{c}' ")
            puts @findtrunk.count
            if(@findtrunk.count > 0)
              flash[:notice] = "该名字的分支已经创建过！！！"
            else
              permission_path = b + ":/branches/" + c
              system e

              @trunk = Trunk.new(:project_id => project_id,:creater =>login,:repository_name => b,:branches => c,:svn_path_type=> "brahches")
              if @trunk.save
                @addsvnmanage = Svnmanage.new(:permission_path => permission_path,:project_id => project_id,:login =>login,:svnpath =>"*",:wrstatus =>"rw")
                if @addsvnmanage.save
                  write_authz
                end
                if(login != "supurman")
                  @addsvnmanage1 = Svnmanage.new(:permission_path => permission_path,:project_id => project_id,:login =>"supurman",:svnpath =>"*",:wrstatus =>"rw")
                  if @addsvnmanage1.save
                    write_authz
                  end
                end
                flash[:notice] = "创建成功！！！"
                redirect_to :controller => 'trunk', :action => 'index', :id => @project
              end 
            end
          else
            flash[:notice] = "请输入参数！！！"
            redirect_to :controller => 'trunk', :action => 'new', :id => @project
          end
        end
      end
    end
  end

  # The method of freeze svn path
  def freeze
    puts "-----------------freeze start-------------------"
    @trunk = Trunk.find(params[:trunk_id])
    if request.post? && !@trunk.frozen?
      @trunk.freeze
      write_authz
    end
    flash[:notice] = "冻结成功！"
    redirect_to :controller => 'trunk', :action => 'index', :id => @project
    puts "-----------------freeze end-------------------"
  end

  # The method of unfreeze svn path
  def unfreeze
    puts "-----------------unfreeze start-------------------"
    @trunk = Trunk.find(params[:trunk_id])
    if request.post? && @trunk.frozen?
      @trunk.unfreeze
      write_authz
    end
    flash[:notice] = "解冻成功！"
    redirect_to :controller => 'trunk', :action => 'index', :id => @project
    puts "-----------------unfreeze end-------------------"
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


