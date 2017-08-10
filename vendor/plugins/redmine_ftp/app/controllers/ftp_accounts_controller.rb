class FtpAccountsController < ApplicationController
  unloadable

  def index

    if User.current.admin?
      # admin用户时显示所有FTP账户
      @ftp_accounts = FtpAccount.find(:all, :conditions => ["status = ?", 1])
    else
      # 显示当前登录用户创建的FTP账户
      @user_id = User.current.id
      @ftp_accounts = FtpAccount.find(:all, :conditions =>["status = ? AND creator_id = ?", 1, @user_id], :order => "expire_time DESC")
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ftp_accounts }
    end
  end

  def add
    if request.post?
      @ftp_account = FtpAccount.new(params[:ftp_account])
      # FTP账户名
      @ftp_account.name = FtpAccount.generate_account_name
      # FTP账户密码
      @ftp_account.password = FtpAccount.random_password
      # 到期时间
      @ftp_account.expire_time = FtpAccount.generate_expire_time
      # 创建者ID
      @ftp_account.creator_id = User.current.id
      # 创建时间
      @ftp_account.created_on = Time.now

      # 数据库保存FTP账户记录成功后，调用脚本生成服务器FTP账户，并发送邮件告知客户
      if @ftp_account.create_account
        # raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
        # # Force ActionMailer to raise delivery errors so we can catch it
        # ActionMailer::Base.raise_delivery_errors = true
        # begin
        #   FtpMailer.deliver_ftp_account_add @ftp_account
        #   # FtpMailer.deliver_ftp_msg_email @ftp_account
        #   flash[:notice] = "FTP账户 #{@ftp_account.name} #{l(:notice_successful_create)} #{l(:notice_email_sent, User.current.mail + " and " + @ftp_account.email)}"
        # rescue Exception => e
        #   flash[:error] = l(:notice_email_error, e.message)
        # end
        # ActionMailer::Base.raise_delivery_errors = raise_delivery_errors

        # 发送FTP账户创建邮件
        FtpMailer.deliver_ftp_account_add @ftp_account
        flash[:notice] = "FTP Account #{@ftp_account.name} #{l(:notice_successful_create)} #{l(:notice_email_sent, User.current.mail + " and " + @ftp_account.email)}"
      end
    end

    redirect_to :controller => 'ftp_accounts', :action => 'index'
  end

  def destroy
    @ftp_account = FtpAccount.find(params[:id])
    @ftp_account.destory_account
    flash[:notice] = @ftp_account.name + l(:notice_successful_delete)

    redirect_to :controller => 'ftp_accounts', :action => 'index'
  end
end
