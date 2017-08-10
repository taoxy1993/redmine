class VpnAccount < ActiveRecord::Base
  unloadable


  # vpn accounts status issued','abandoned'
  # 'issued' 表示已签发
  # 'abandoned' 表示已废弃
  STATUS_ISSUED = 'issued'
  STATUS_ABANDONED = 'abandoned'

  # 状态值，表示证书是否已经续签
  # 'N' 表示没有续签
  # 'Y' 表示已续签
  RESUMED_NO = 'N'
  RESUMED_YES = 'Y'


  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'

  validates_presence_of :owner_id


=begin
VPN账户续签，更新resumed字段
=end
  def resume_account
    update_attributes :resumed => RESUMED_YES
  end

=begin
废弃VPN账户
=end
  def obsolete_account
    update_attributes :status => STATUS_ABANDONED
  end

=begin
销毁VPN账户
=end
  def destroy_account
    # 调用脚本删除服务器上的vpn证书
    if VpnAccount.destroy_cert(self.cert_name)

      # 更新VPN账户状态,标记为已废弃和已续签
      self.obsolete_account

      # VPN证书删除通知邮件
      VpnMailer.deliver_vpn_account_destroy(self)
    end
  end

  private

=begin
创建VPN账户
=end
  def self.create_account(user)
    # 获取用户名
    user_name = user.login

    # 获取用户证书有效期(天)
    valid_days = VpnAccount.get_user_valid_days user_name

    # 调用脚本生成VPN证书
    cert_name = VpnAccount.generate_cert(user_name, valid_days)

    @vpn_account = VpnAccount.new
    # vpn证书名称
    @vpn_account.cert_name = cert_name
    # 证书拥有者
    @vpn_account.owner = user
    # 证书创建时间
    @vpn_account.created_on = Time.now
    # 到期时间
    @vpn_account.expire_time = Time.now + valid_days.to_i.day
    # 有效期(天)
    @vpn_account.valid_days = valid_days

    if @vpn_account.save
      # 发送带证书附件的通知邮件
      VpnMailer.deliver_vpn_account_add(@vpn_account)

      # 删除/tmp目录下的临时证书
      VpnAccount.clear_tmp_cert(@vpn_account.cert_name)

      #
      @vpn_accounts = VpnAccount.find(:all, :conditions => ["owner_id = ? AND id <> ?", user.id, @vpn_account.id])
      @vpn_accounts.each do |vpn_account|
        vpn_account.resume_account
      end
    end

  end

=begin
调用脚本，在服务器上生成vpn证书和.conf文件
=end
  def self.generate_cert(user_name, vpn_days)
    # 生成时间戳
    time_stamp = Time.now.strftime("%y%m%d%H%M%S")

    # 证书名称
    cert_name = "tls-" + user_name + "-" + time_stamp

    cmd = "/usr/bin/sudo /opt/ioa/bin/vpnkey.sh" + " add " + user_name +" " +  time_stamp + " " + vpn_days + " 1>&2"
    ret = system(cmd)
    Rails.logger.info "Execute command: #{cmd}"

    if ret
      VpnAccount.generate_client_conf(user_name, cert_name)
    end

    return cert_name
  end

=begin
生成用户客户端配置文件
=end
  def self.generate_client_conf(user_name, cert_name)
    conf_file_content= "
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
key  JN-tls-" + user_name + ".key
cert JN-tls-" + user_name + ".crt

comp-lzo
verb 3
"
    file = File.new("/tmp/" + cert_name + ".conf", "w")
    file.puts conf_file_content
    file.close
  end

=begin
调用脚本删除服务器上的vpn证书
=end
  def self.destroy_cert(cert_name)
    cmd = "/usr/bin/sudo /opt/ioa/bin/vpnkey.sh" + " del " + cert_name + " 1>&2"
    system(cmd)
    Rails.logger.info "Execute command: #{cmd}"
  end

=begin
删除服务器/tmp目录临时存放的vpn证书文件
=end
  def self.clear_tmp_cert(cert_name)
    system ("rm -f /tmp/" + cert_name + ".*")
  end

=begin
续签VPN证书
=end
  def self.renewal_cert
    @vpn_accounts = VpnAccount.find(:all,
                                    :conditions => ["resumed = 'N' AND status = 'issued' AND DATEDIFF(expire_time, NOW()) < 3"],
                                    :order => "created_on ASC")
    @vpn_accounts.each do |vpn_account|
      VpnAccount.create_account(vpn_account.owner)

      vpn_account.resume_account
    end
  end

=begin
销毁过期VPN证书
=end
  def self.destory_expire_cert
    @vpn_accounts = VpnAccount.find(:all,CompileController
                                    :conditions => ["resumed = 'Y' AND status = 'issued' AND expire_time < NOW()"],
                                    :order => "created_on ASC")
    @vpn_accounts.each do |vpn_account|
      vpn_account.destroy_account
    end
  end

=begin
获取不同用户vpn证书保留天数
=end
  def self.get_user_valid_days(username)
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

end
