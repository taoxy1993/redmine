class CompileController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  helper :sort
  include SortHelper

  def index
    sort_init 'asc'
    sort_update %w()

    @identifier = Project.find(@project)
    project_id = @identifier.id
    @compile = Compile.find(:all,:conditions=>"project_id = '#{project_id}'")
    @compile.each do |compile|
      if(compile.branches == 'trunk'||compile.branches == 'HEAD')
          compile.branches='主线'
      end
    end
  end

  def new
    identifier = Project.find(@project)
    project_id = identifier.id
    @trunk = Trunk.find(:all,:conditions=>"project_id = '#{project_id}' and svn_path_type != 'tags'")
    @trunk.each do |trunk|
      puts trunk.branches
       if(trunk.branches == "trunk"||trunk.branches == 'HEAD'||trunk.branches == nil)
         trunk.branches = '主线'
       end
    end
    if request.post?
      if(params[:new]==nil || params[:new] == "")
        flash[:notice] = "输入不能为空！！！"
        redirect_to :controller => 'compile', :action => 'index', :id => @project
      else
        @produce = Compile.find(:all,:conditions=>"produce = '#{params[:new]}' and branches = '#{params[:trunk]}' ")
        if (@produce.count > 0)
             flash[:notice] = "产品已经被创建过！！！"
             redirect_to :controller => 'compile', :action => 'index', :id => @project
        else
          @identifier = Project.find(@project)
          project_id = @identifier.id
          e = params[:trunk]
          if(e == "trunk"||e == 'HEAD'||e == nil||e == "主线")
              e = "HEAD"
          end
          @compile = Compile.new(:project_id => project_id,:produce => params[:new],:branches => e)
          if @compile.save
            flash[:notice] = "创建成功！"
            redirect_to :controller => 'compile', :action => 'index', :id => @project
          end
        end
       end
    end
  end

  def destroy
    @compile = Compile.find_by_produce(params[:produce])
    @compile.destroy
    flash[:notice] = "删除成功！"
    redirect_to :controller => 'compile', :action => 'index', :id => @project
  end

  def add
    @propuct = params[:produce]
    @branches = params[:branches]
    if request.post?
      t = Time.new
      date = t.strftime("%Y-%m-%d %H:%M:%p")

      @user = User.find(User.current)
      puts @user.login

      @identifier = Project.find(@project)

      @publiclib = Publiclib.new(:project_id => @identifier.id,:username => @user.login,:reserved3=> params[:reserved3],
                   :releasedate => date,:releaseversion => params[:releaseversion],:releasenote => params[:releasenote],
                   :reserved1 => params[:reserved1],:reserved2 => '12345678')
      if @publiclib.save
        redirect_to :controller => 'compile',
                    :action => 'docompile',
                    :id => @project,
                    :produce => params[:reserved1],
                    :branches => params[:reserved3],
                    :usefor => 'ReleaseVersion',
                    :description => params[:releasenote]
      end
    end
  end

  def docompile
    t = Time.new
    date = t.strftime('%Y-%m-%d-%H:%M:%S')

    puts date
    ramdom = newpass(10)
    puts ramdom

    @user = User.find(User.current)
    puts @user.login

    @identifier = Project.find(@project)
    @branches = params[:branches]
    @propuct = params[:produce]
    @repository = params[:repository]
    @servername = params[:servername]
    if(@branches == "主线")
      @branches = "HEAD"
    end

    if((@identifier.identifier == "lotus")||(@identifier.identifier == "istb3"))
      a = "/opt/ioa/bbb/" + @repository + "/"
    else
      a = "/opt/ioa/bbb/svn/"
    end

    if File.directory? a
    else
      Dir.mkdir(a)
    end

    @identifier = Project.find(@project)
    b = a + @identifier.identifier
    project_id = @identifier.id
    puts b
    if File.directory? b
    else
      Dir.mkdir(b)
    end

    @propuct = params[:produce]
    @showpathdir = @branches
    c = b + "/" + @showpathdir
    if File.directory? c
    else
      Dir.mkdir(c)
    end
    @addp = c + "/" + @propuct
    if File.directory? @addp
    else
      Dir.mkdir(@addp)
    end

    d = date + "-" + ramdom + "-" + @user.login
    @e = @addp + "/" + d
    puts d
    puts @e

    if File.directory? @e
    else
      Dir.mkdir(@e)
    end

    if((@branches == "trunk")||(@branches == "主线")||(@branches == "HEAD")||(@branches==nil))
    	 @m = "tag=HEAD"
    	 trunks = Trunk.find_by_sql("select repository_name from trunks where svn_path_type = 'trunk' and project_id = '#{project_id}'")
      	temp = trunks[0]
    	 #p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/trunk"
    	 p = "svnpath=http://mcv.inspur.com/svn/"+ temp.repository_name + "/trunk"
    	 svnpath="http://mcv.inspur.com/svn/"+ temp.repository_name + "/trunk"
    else
    	 brachesname = @branches
      trunks = Trunk.find_by_sql("select repository_name from trunks where branches = '#{brachesname}' and project_id = '#{project_id}'")
      temp = trunks[0]
      @m = "tag=" + params[:branches]
      #p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/branches/" + @branches
    	 p = "svnpath=http://mcv.inspur.com/svn/"+ temp.repository_name + "/branches/" + @branches
      svnpath="http://mcv.inspur.com/svn/"+ temp.repository_name + "/branches/" + @branches
    end

   if ((@identifier.identifier == "lotus")||(@identifier.identifier == "istb3"))
      require "rubygems"
      require "mysql"

         puts "++++++++++++++++++++++++++++++++++"
      p = svnpath;
      @option = params[:option]
      db = Mysql.real_connect('127.0.0.1', 'inspur', 'inspur123456', 'JOBS')
       puts "!!!!!!!!!!!!!!!!!!!!!!!!!!++!!!"
      table = "job"
      db.query("insert into #{table} (ID,code,code_type,branch,product,os,hostname,url,status,cancel,get_res,mail_to,path,output,usrname,compile) values('','#{@identifier.identifier}','#{@repository}','#{@branches}','#{@propuct}','#{@servername}','','','not_start','hold','no','','#{p}','#{@e}','#{d}','#{@option}')")
      db.close
 puts "!!!!!!!!!!!!!!!======!!!!!!!!!!!!!!"

      @outpath = "http://mcv.inspur.com/bbb/" + @repository + "/" +@identifier.identifier+"/"+@branches+"/"+@propuct+"/"+d
      @logpath = "http://mcv.inspur.com/bbb/" + @repository + "/" +@identifier.identifier+"/"+@branches+"/"+@propuct+"/"+d+"/BUILD.LOG"

    else
      f = a + "redmine/"
      if File.directory? f
      else
        Dir.mkdir(f)
      end
      puts f

      g = f + ramdom + "svn.redmine"
      h = g + ".tmp"
      puts g

      fd = File.new(h, "w+")

      i = "src=" + temp.repository_name
      j = "product=" + @propuct
      k = "PathOutput=" + @e
      l = "user=tmp\n"

      n = "name=" + @identifier.name

      # @o = Repository.find_by_project_id(@identifier.id)
      # puts @o
      # p = "svnpath=" + @o.url

      fd.puts i
      fd.puts j
      fd.puts k
      fd.puts l
      fd.puts @m
      fd.puts n
      fd.puts p
      fd.close

      File.rename( h, g )

      @outpath = "http://mcv.inspur.com/bbb/svn/"+@identifier.identifier+"/"+@showpathdir+"/"+@propuct+"/"+d
      @logpath = "http://mcv.inspur.com/bbb/svn/"+@identifier.identifier+"/"+@showpathdir+"/"+@propuct+"/"+d+"/BUILD.LOG"
    end

     puts @outpath
     puts @logpath

    # ========================================================================
    # 生成编译用途文件，用于判断编译的用途
    # usefor: 编译用途
    # usefor_description: 编译用途描述
    # ========================================================================
    usefor = params[:usefor]
    usefor_description = params[:description]
    unless usefor.empty?
      usefor_file_path = @e + "/" + usefor
      usefor_file = File.new(usefor_file_path, "wb+")
      usefor_file.puts usefor_description
      usefor_file.close
    end
    # ========================================================================

     @publiclib = Publiclib.find(:all,:conditions=>"reserved2 = '12345678'")

     @publiclib.each do |publiclib|
       publiclib.reserved2 = @outpath
       publiclib.save
     end
     flash[:notice] = "正在进行编译！"

  end

  def canclecompile
    @output = params[:outpath]
    require "rubygems"
    require "mysql"
    db = Mysql.real_connect('127.0.0.1', 'inspur', 'inspur123456', 'JOBS')
    #db.options(Mysql::SET_CHARSET_NAME, 'utf8')
    table = "job"
    db.query("update #{table} set cancel='cancel' where output='#{@output}'")
    db.close
    redirect_to :controller => 'compile', :action => 'index', :id => @project
    flash[:notice] = "编译已取消！"
  end

  def compileoption
    @branches = params[:branches]
    @propuct = params[:produce]

    # 编译用途
    @usefor = params[:usefor]
    # 用途描述
    @description = params[:description]

    puts "=================action compileoption====================="
    puts "项目名称：----->#{@project}"
    puts "版 本 树：----->#{@branches}"
    puts "产品名称：----->#{@propuct}"
    puts "编译用途：----->#{@usefor}"
    puts "用途描述：----->#{@description}"
    puts "=========================================================="

    @identifier = Project.find(@project)
	   if ((@identifier.identifier == "lotus")||(@identifier.identifier == "istb3"))
	     @option1 = "1.compile MBoot"
	     @option2 = "2.compile Kernel and copy zImage to android system"
	     @option3 = "3.compile Supernova and copy to tftp image directory"
	     @option4 = "4.compile android and copy to tftp image directory"
	     @option5 = "5.compile ddi,you should update the library manually && you should confrim istb3 svn code ready!!!"
	     @option6 = "6.compile ALL and prepare all the tftp image"
	   else
	     @option1 = "1.compile SDK"
	     @option2 = "2.compile qt"
	     @option3 = "3.compile thirpart lib"
	     @option4 = "4.compile all part"
	     @option5 = "5.compile the svn tree"
	     @option6 = "6.only create the image"
	   end
      if request.post?
        puts params[:repository]
        puts params[:chooseoption]
        puts @project
        puts @propuct
        puts @branches
        @chooseoption = params[:chooseoption]
        @repository = params[:repository]
        @servername = params[:servername]
        redirect_to :controller => 'compile',
                    :action => 'docompile',
                    :id => @project,
                    :produce => @propuct,
                    :branches => @branches,
                    :option => @chooseoption,
                    :repository =>@repository,
                    :servername => @servername,
                    :usefor => @usefor,
                    :description => @description
      end
  end

  def choose
    # @identifier = Project.find(@project)
    # @branches = params[:branches]
    # @propuct = params[:produce]
    #
    # if((@identifier.identifier == "lotus")||(@identifier.identifier == "istb3"))
    #   redirect_to :controller => 'compile', :action => 'compileoption', :id => @project, :produce => @propuct,:branches => @branches
    # else
    #   redirect_to :controller => 'compile', :action => 'docompile', :id => @project, :produce => @propuct, :branches => @branches, :option => 0 ,:repository => 'svn',:servername => 'linux'
    # end

    @project
    @branches = params[:branches]
    @propuct = params[:produce]

    project_identifier = @project.identifier

    if request.post?
      @project
      @branches = params[:branches]
      @propuct = params[:produce]
      @usefor = params[:usefor]
      @description = params[:description]

      puts "=======================action choose======================="
      puts "项目名称：----->#{@project}"
      puts "项目标识：----->#{@project}"
      puts "版 本 树：----->#{@branches}"
      puts "产品名称：----->#{@propuct}"
      puts "编译用途：----->#{@usefor}"
      puts "用途描述：----->#{@description}"
      puts "==========================================================="

      if((project_identifier == "lotus") || (project_identifier == "istb3"))
        redirect_to :controller => 'compile',
                    :action => 'compileoption',
                    :id => @project,
                    :produce => @propuct,
                    :branches => @branches,
                    :usefor => @usefor,
                    :description => @description
      else
        redirect_to :controller => 'compile',
                    :action => 'docompile',
                    :id => @project,
                    :produce => @propuct,
                    :branches => @branches,
                    :option => 0 ,
                    :repository => 'svn',
                    :servername => 'linux',
                    :usefor => @usefor,
                    :description => @description
      end
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id])
  end

  def newpass(len)
    newpass = ""
    1.upto(len){ |i| newpass << rand(10).to_s}
    return newpass
  end
end
