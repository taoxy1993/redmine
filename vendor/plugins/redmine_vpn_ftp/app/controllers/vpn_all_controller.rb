class VpnAllController < ApplicationController
  unloadable

  $VPNCMD = "/usr/bin/sudo /opt/ioa/bin/vpnkey.sh"

  def index
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    # 查询所有在有效期内，签发状态为"resumed"的签发记录
    @vpn_all = Vpn_manager.find_by_sql("SELECT vpn_managers.*,  users.firstname, users.lastname, users.mail FROM vpn_managers , users WHERE vpn_managers.wknum = users.id AND (s_status = 'issued' AND resumed = 'Y' AND t_expire > now()) ORDER BY t_create DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vpn_all }
    end
  end

  def vpn_kill
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    # 临时签发，页面进行"kill"操作后，修改resumed = "N"，不进行续签
    @vpn = Vpn_manager.find_by_id(params["user_id"])

    @vpn.update_attribute(:resumed, "N")

    redirect_to :action => 'index'

  end

  def vpn_add
    unless User.current.admin? or User.current.svnmanage? or User.current.teamleader?
      render_404
      return
    end

    # 获取签发用户对象
    @user = User.find_by_id(params["user"]["id"])

    if @user == nil
      flash[:error] = "被签发人员不能为空"
    else

      # 获取用户名
      user_name = @user.mail.split("@")[0]

      # 获取用户证书有效期(天)
      vpn_days = Vpn_manager.get_vpn_days(user_name)

      # 生成时间戳
      time = Time.new
      time_stamp = time.strftime("%y%m%d%H%M%S")

      # 调用服务器脚本，生成vpn证书
      Vpn_manager.vpn_crt_generate(user_name, time_stamp, vpn_days)


      # 签发时间、有效期截止时间
      s_time = time.strftime("%Y-%m-%d %H:%M:%S")

      vpn_max_time = vpn_days.to_i*24*3600
      e_time = (time + vpn_max_time).strftime("%Y-%m-%d %H:%M:%S")

      # 读取vpn证书".key"".crt"文件的内容
      d_key = Vpn_manager.vpn_read_file("/tmp/" + $FileBaseReal + ".key", 8000)
      d_crt = Vpn_manager.vpn_read_file("/tmp/"+ $FileBaseReal + ".crt", 8000)

      # vpn证书前缀
      k_name = "tls-" + user_name + "-" + time_stamp

      # # 获取是否续签标志
      # is_ressumed = params["resumed"]
      # resumed = ""
      # if is_ressumed == "yes"
      #   resumed = "Y"
      # else
      #   resumed = "N"
      # end

      # 添加签发记录到数据库
      @vpn_m = Vpn_manager.new

      @vpn_m.wknum = params["user"]["id"]
      @vpn_m.t_create = s_time
      @vpn_m.t_expire = e_time
      @vpn_m.d_key = d_key
      @vpn_m.d_crt = d_crt
      @vpn_m.s_status = 'issued'
      @vpn_m.k_name = k_name
      @vpn_m.resumed = "Y"

      @vpn_m.save

      # 发送邮件
      user_mail =  @user.mail
      mail_to = @user.lastname + @user.firstname
      mail_k = @user.mail.split("@")[0]
      t_create = s_time
      t_expire = e_time
      email_msg = {:user_mail => user_mail, :mail_to => mail_to,
                   :mail_k => mail_k, :t_create => t_create,
                   :t_expire => t_expire, :vpn_days => vpn_days}

      raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
      # Force ActionMailer to raise delivery errors so we can catch it
      ActionMailer::Base.raise_delivery_errors = true
      begin
        UserMailer.deliver_vpn_email(email_msg)
        flash[:notice] = l(:notice_email_sent, @user.mail)
      rescue Exception => e
        flash[:error] = l(:notice_email_error, e.message)
      end
      ActionMailer::Base.raise_delivery_errors = raise_delivery_errors

      # 删除服务器/tmp目录临时存放的vpn证书文件
      system ("rm -f /tmp/" + $FileBaseReal + ".*")

    end

    redirect_to :action => 'index'
  end

end