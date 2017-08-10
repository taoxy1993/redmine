class FtpAllController < ApplicationController
  unloadable
  $cmd_sudo = "/usr/bin/sudo -b "
  $cmd_ftpuser = "/opt/ioa/bin/ftpuser.sh"

  $svnrootserver = "10.8.10.2"
  $ftp_max_expire_time = 1800

  def index
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    if User.current.admin?
      # admin用户时显示所有FTP账户
      @ftp_all = Ftp_manager.find(:all)
    else
      # 显示当前登录用户创建的FTP账户
      @user_id = User.current.id
      @ftp_all = Ftp_manager.find(:all, :conditions =>["creator = ?", @user_id], :order => "expire DESC")
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ftp_all }
    end
  end

  def ftp_kill
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    # 删除服务器FTP账户
    ftpuser = params["username"]
    ret = Ftp_manager.ftp_account_destory(ftpuser)

    if ret
      # 删除数据库FTP账户记录
      @ftp = Ftp_manager.find_by_name(ftpuser)
      @ftp.destroy
    end

    redirect_to :action => 'index'
  end

  def ftp_new
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    # 数据库添加FTP账户记录
    time = Time.new
    ftp_max_time = $ftp_max_expire_time
    ftp_name = User.current.mail.split("@")[0] + "_" + newpass(8)
    ftp_password = newpass(9)
    ftp_expire = (time + ftp_max_time).strftime("%Y-%m-%d %H:%M:%S")
    ftp_customermail = params["customermail"]

    @ftp_m = Ftp_manager.new

    @ftp_m.name = ftp_name
    @ftp_m.passwd = ftp_password
    @ftp_m.creator = User.current.id
    @ftp_m.expire = ftp_expire
    @ftp_m.customer = ftp_customermail

    mail_msg = {:customer_mail => ftp_customermail, :creator_mail => User.current.mail,
                :ftp_name => ftp_name, :ftp_password => ftp_password, :ftp_expire => ftp_expire}

    if @ftp_m.save
      # 数据库保存FTP账户记录成功后，调用脚本生成服务器FTP账户，并发送邮件告知客户
      if Ftp_manager.ftp_account_generate(ftp_name)

        raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
        # Force ActionMailer to raise delivery errors so we can catch it
        ActionMailer::Base.raise_delivery_errors = true
        begin
          UserMailer.deliver_ftp_email(mail_msg)
          flash[:notice] = ftp_name + " 已经创建，" + l(:notice_email_sent, User.current.mail + " and " + ftp_customermail)
        rescue Exception => e
          flash[:error] = l(:notice_email_error, e.message)
        end
        ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
      end
    else
      flash[:error] = "您输入的邮件地址---(" + params["customermail"] + ")---不合法"
    end

    redirect_to :action => 'index'
  end

  def newpass(len)
    # 随机生成长度为len的字符串
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

end