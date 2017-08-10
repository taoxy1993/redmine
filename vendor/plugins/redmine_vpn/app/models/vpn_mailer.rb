# VpnMailer extends from Mailer

class VpnMailer < Mailer

=begin
签发vpn证书的邮件通知
=end
  def vpn_account_add(vpn_account)
    # 用户邮箱
    user_email = vpn_account.owner.mail
    # 用户名
    user_name = vpn_account.owner.login

    recipients user_email
    subject "VPN INFORMATION"
    body :vpn_account => vpn_account
    render_multipart('vpn_account_add', body)

    # 附件根证书
    attachment :content_type => 'application/crt',
               :body => File.read("/tmp/" + vpn_account.cert_name + ".ca.crt"),
               :filename => "JN-tls-ca.crt"

    # 附件配置文件
    attachment :content_type => 'application/conf',
               :body => File.read("/tmp/" + vpn_account.cert_name + ".conf"),
               :filename => "JN-tls" + user_name + ".conf"

    # VPN密钥
    attachment :content_type => 'application/key',
               :body => File.read("/tmp/" + vpn_account.cert_name + ".key"),
               :filename => "JN-tls" + user_name + ".key"

    # VPN证书
    attachment :content_type => 'application/crt',
               :body => File.read("/tmp/" + vpn_account.cert_name + ".crt"),
               :filename => "JN-tls" + user_name + ".crt"

  end

=begin
删除vpn证书的邮件通知
=end
  def vpn_account_destroy(vpn_account)
    recipients vpn_account.owner.mail
    subject "VPN CHECK REMINDER"
    body :vpn_account => vpn_account
    render_multipart('vpn_account_destroy', body)
  end

end