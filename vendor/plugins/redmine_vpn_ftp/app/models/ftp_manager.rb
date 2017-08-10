class Ftp_manager < ActiveRecord::Base
  validates_format_of(:customer, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "邮件地址不合法")

  $cmd_sudo = "/usr/bin/sudo -b "
  $cmd_ftpuser = "/opt/ioa/bin/ftpuser.sh"

=begin
生成FTP账户
=end
  def self.ftp_account_generate(ftpuser)
    cmd = $cmd_sudo + $cmd_ftpuser + " -a " + ftpuser
    ret = system(cmd)
    return ret
  end

=begin
销毁FTP账户
=end
  def self.ftp_account_destory(ftpuser)
    cmd = $cmd_sudo + $cmd_ftpuser + " -d " + ftpuser
    ret = system(cmd)
    return ret
  end

=begin
检测FTP账户，删除已过期账户
=end
  def self.is_expire
    Rails.logger.info "["+Time.now.strftime('%Y-%m-%d %H:%M:%S').to_s+"] ftp is expire."
    system("echo '-------------ftp check------------'")
    @ftp_all = Ftp_manager.find_by_sql("SELECT * FROM ftp_managers WHERE expire < NOW()")

    if @ftp_all != nil
      @ftp_all.each do |ftp|
        customer_mail = ftp.customer
        ftpuser = ftp.name

        ret = Ftp_manager.ftp_account_destory(ftpuser)

        if ret
          system("echo 'delete success !'")

          ftp.destroy

          UserMailer.deliver_ftp_msg_email(customer_mail, ftpuser)
        else
          system("echo 'delete fail !'")
        end

      end
    end
  end
end