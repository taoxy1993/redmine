class Vpn_manager < ActiveRecord::Base
  #validates_format_of(:mail, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "邮件地址不合法")

  $FileBaseReal = ""
  $FileBaseUsed = ""

  $VPNCMD = "/usr/bin/sudo /opt/ioa/bin/vpnkey.sh"

=begin
调用脚本，在服务器上生成vpn证书
=end
  def self.vpn_crt_generate(user_name, time_stamp, vpn_days)

    $FileBaseReal = "tls-" + user_name + "-" + time_stamp
    $FileBaseUsed = "tls-" + user_name
    @cmd = $VPNCMD + " add" + " " + user_name +" " +  time_stamp + " " + vpn_days + " 1>&2"
    @ret = system(@cmd)
    if @ret
      @vpn_cfg_file= "
### NOTE:
### TelCom: 58.56.83.194
### UniCom: 218.57.146.138
### TCP port: 1194, 443, 60009
### UDP port: 1194
dev tun
client

proto tcp
remote 58.56.83.198 443
remote 218.57.146.138 443

#proto udp
#remote 58.56.83.198 1194
#remote 218.57.146.138 1194

resolv-retry infinite
nobind
reneg-sec 86400
ns-cert-type server

persist-key
persist-tun
ca   JN-tls-ca.crt
key  JN-" + $FileBaseUsed + ".key
cert JN-" + $FileBaseUsed + ".crt

comp-lzo
verb 3
"
      fh = File.new("/tmp/" + $FileBaseReal + ".conf", "w")
      fh.puts @vpn_cfg_file
      fh.close
    end
  end

=begin
调用脚本删除服务器上的vpn证书
=end
  def self.vpn_crt_destory(k_name)
    @cmd = $VPNCMD + " del " + k_name + " 1>&2"
    system(@cmd)
  end


=begin
获取不同用户vpn证书有效期(天)
=end
  def self.get_vpn_days(username)
    vpn_days = 0
    if username  == 'hehy'
      vpn_days = 10;
    elsif username == 'liuxiaowei' || username == 'lihsh'
      vpn_days = 365 * 2;
    elsif username == 'liuchl'
      vpn_days = 30 * 6;
    elsif username == 'chenzhg'
      vpn_days = 35 * 2;
    else
      vpn_days = 14;
    end
    return vpn_days.to_s
  end

=begin
检查vpn证书在到期前3天是否需要自动续签
=end
  def self.is_resumed
    Rails.logger.info "["+Time.now.strftime('%Y-%m-%d %H:%M:%S').to_s+"] vpn is resumed."
    system("echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>vpn check<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'")
    @vpn_all = Vpn_manager.find_by_sql("SELECT vpn_managers.*, users.firstname, users.lastname FROM vpn_managers LEFT JOIN users ON  vpn_managers.wknum = users.id where resumed='Y' AND s_status='issued' AND t_expire > NOW() AND to_days(t_expire) - to_days(NOW()) < 3 ORDER BY t_create DESC")
    if @vpn_all != nil
      @vpn_all.each do |vpn|
        # 获取用户名
        user_name = vpn.k_name.split("-")[1].strip

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
        k_name = "tls-" + vpn.k_name.split("-")[1].strip + "-" + time_stamp

        # 添加签发记录到数据库
        @vpn_m = Vpn_manager.new

        @vpn_m.wknum = vpn.wknum
        @vpn_m.t_create = s_time
        @vpn_m.t_expire = e_time
        @vpn_m.d_key = d_key
        @vpn_m.d_crt = d_crt
        @vpn_m.s_status = 'issued'
        @vpn_m.k_name = k_name
        @vpn_m.resumed = "Y"

        @vpn_m.save

        # 发送邮件
        @user = User.find_by_id(vpn.wknum)
        user_mail =  @user.mail
        mail_to = @user.lastname + @user.firstname
        mail_k = @user.mail.split("@")[0]

        email_msg = {:user_mail => user_mail, :mail_to => mail_to,
                     :mail_k => mail_k, :t_create => s_time,
                     :t_expire => e_time, :vpn_days => vpn_days}
        UserMailer.deliver_vpn_email(email_msg)

        Vpn_manager.update(vpn.id, {:resumed => "N"})

        # 删除服务器/tmp目录临时存放的vpn证书文件
        system ("rm -f /tmp/" + $FileBaseReal + ".*")
      end
    end
  end

=begin
检查vpn证书是否过期，删除过期vpn证书
=end
  def self.is_abandoned
    @vpn = Vpn_manager.find_by_sql("SELECT * FROM vpn_managers where (resumed='N' AND s_status='issued' AND t_expire < NOW()) ORDER BY t_create DESC")
    if @vpn != nil
      @vpn.each do |vpn|

        # 调用脚本删除服务器上的vpn证书
        ret = vpn_crt_destory(vpn.k_name)
        if ret

          Vpn_manager.update(vpn.id, {:s_status => "abandoned"})

          @user = User.find_by_id(vpn.wknum)
          user_mail =  @user.mail
          mail_to = @user.lastname + @user.firstname

          str_time = vpn.t_create.to_s
          t_create = Time.parse(str_time).strftime("%Y-%m-%d %H:%M:%S")

          UserMailer.deliver_vpn_msg_email(user_mail, mail_to, t_create)
        end
      end
    end
  end

=begin
读取vpn证书文件
=end
  def self.vpn_read_file(vpn_path, vpn_len)
    buf = ""
    file = open(vpn_path)
    file.read(vpn_len, buf)
    file.close
    return buf
  end

end