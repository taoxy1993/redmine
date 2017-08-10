class FtpAccount < ActiveRecord::Base
  unloadable

  # ftp accounts 状态,1代表正常,0表示废弃不可用
  STATUS_ACTIVE     = 1
  STATUS_DELETED    = 0

  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'

  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "邮件地址不合法"
  validates_length_of :email, :maximum => 60

  # 废弃FTP账户，更新FTP账户状态为'0',
  def obsolete_account
    update_attributes :obsoleted_on =>Time.now, :status => STATUS_DELETED
  end

=begin
创建FTP账户
=end
  def create_account
    # 保存FTP账户信息到数据库
    self.save

    # 调用脚本创建FTP账户根目录
    cmd = "#{APP_CONFIG['cmd_sudo']} #{APP_CONFIG['cmd_ftpuser']} -a #{self.name}"
    ret = system(cmd)
    Rails.logger.info "Execute command: #{cmd}"

    return ret
  end

=begin
销毁FTP账户
=end
  def destory_account
    # 调用脚本删除FTP账户根目录
    cmd = "#{APP_CONFIG['cmd_sudo']} #{APP_CONFIG['cmd_ftpuser']} -d #{self.name}"
    ret = system(cmd)
    Rails.logger.info "Execute command: #{cmd}"

    # 更新FTP账户状态,标记为已废弃
    if ret
      self.obsolete_account
    end
  end

=begin
获取FTP服务器主机名称
=end
  def get_ftp_host
    APP_CONFIG['host_name']
  end

=begin
检测FTP账户，删除已过期账户
=end
  def self.destory_expire_accounts

    @ftp_accounts = FtpAccount.find(:all, :conditions => ["status = ? AND expire_time < NOW()", 1])

    if @ftp_accounts != nil
      @ftp_accounts.each do |ftp_account|
        Rails.logger.info "Destory expire ftp accounts start."

        if ftp_account.destory_account
          system("echo 'delete success !'")
          Rails.logger.info "Destory ftp accounts success."
          # 发送FTP到期销毁邮件
          FtpMailer.deliver_ftp_account_destory ftp_account
        else
          system("echo 'delete fail !'")
          Rails.logger.info "Destory ftp accounts fail."
        end

        Rails.logger.info "Destory expire ftp accounts end."
      end
    end
  end

  private

=begin
生成长度9位的随机password
=end
  def self.random_password
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    password = ''
    9.times { |i| password << chars[rand(chars.size-1)] }
    return password
  end

=begin
生成FTP账户名
=end
  def self.generate_account_name
    User.current.mail.split("@")[0] + "_" + FtpAccount.random_password
  end

=begin
生成FTP账户到期时间
=end
  def self.generate_expire_time
    Time.now + APP_CONFIG['ftp_max_time'].to_i
  end

end
