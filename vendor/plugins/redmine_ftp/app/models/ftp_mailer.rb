# FtpMailer extends from Mailer

class FtpMailer < Mailer

=begin
创建FTP账户的邮件通知
=end
  def ftp_account_add(ftp_account)
    recipients ftp_account.email
    # @TODO 去除注解
    # cc ftp_account.creator.mail
    subject "FTP INFORMATION"
    body :ftp_account => ftp_account
    render_multipart('ftp_account_add', body)
  end

=begin
删除FTP账户的邮件通知
=end
  def ftp_account_destory(ftp_account)
    recipients ftp_account.email
    subject "FTP CHECK REMINDER"
    body :ftp_account => ftp_account
    render_multipart('ftp_account_destory', body)
  end

end