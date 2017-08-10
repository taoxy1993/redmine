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
    @trunk = Trunk.find(:all,:conditions=>"project_id = '#{project_id}' and createdate != 'tags'")
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
        redirect_to :controller => 'compile',:action => 'docompile',:id => @project,:produce =>params[:reserved1],:branches => params[:reserved3]
      end
    end
  end
  
  def docompile
    t = Time.new
    date = t.strftime("%Y%m%d")
    
    puts date    
    ramdom = newpass(10)
    puts ramdom
    
    @user = User.find(User.current)
    puts @user.login
    
    a = "/opt/ioa/bbb/svn/"
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
    @showpathdir = params[:branches]
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
    
    f = a + "redmine/"
    if File.directory? f
    else
      Dir.mkdir(f)
    end    
    puts f
    
     g = f + ramdom + "svn.redmine"
     h = g + ".tmp"
     puts g
     @branches = params[:branches]
     if((@branches == "trunk")||(@branches == "主线")||(@branches == "HEAD")||(@branches==nil))
	@m = "tag=HEAD"
	trunks = Trunk.find_by_sql("select trunk from trunks where createdate = 'trunk' and project_id = '#{project_id}'")
	temp = trunks[0]
	p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/trunk"
     else
	brachesname = @branches  
      trunks = Trunk.find_by_sql("select trunk from trunks where branches = '#{brachesname}' and project_id = '#{project_id}'")
      temp = trunks[0]
      @m = "tag=" + params[:branches]
      p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/branches/" + @branches
     end
     fd = File.new(h, "w+") 
     
     i = "src=" + temp.trunk
     j = "product=" + @propuct 
     k = "PathOutput=" + @e
     l = "user=tmp\n"
     
     n = "name=" + @identifier.name
     
     #@o = Repository.find_by_project_id(@identifier.id)
     #puts @o
     #p = "svnpath=" + @o.url
     
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
     
     #@outpath = "http://mcv.inspur.com/bbb/svn/iSTB2/rulai/20120629-7313938836-admin"
     #@logpath = "http://mcv.inspur.com/bbb/svn/iSTB2/rulai/20120629-7313938836-admin/BUILD.LOG"
     puts @outpath
     puts @logpath
     
     @publiclib = Publiclib.find(:all,:conditions=>"reserved2 = '12345678'") 
      
     @publiclib.each do |publiclib|
       publiclib.reserved2 = @outpath
       publiclib.save
     end
     flash[:notice] = "正在进行编译！"
    
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
