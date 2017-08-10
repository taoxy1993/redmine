require 'ar_condition'

class UserMailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues
  helper :custom_fields

  include ActionController::UrlWriter
  include Redmine::I18n

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

=begin
签发vpn证书的邮件通知
=end
  def vpn_email(msg)
    recipients msg[:user_mail]
    from "yuzhili@inspur.com"
    subject "VPN INFORMATION"
    body :msg => msg
    content_type "multipart/mixed"
    part :content_type => "text/plain",
         :body => render(:file => "vpn_email.text.plain.rhtml",
                         :body => body,
                         :layout => 'usermailer.text.plain.erb')
    # part :content_type => "text/html",
    #      :body => render_message("vpn_email.text.html.rhtml", body)

    # 附件根证书
    attachment :content_type => 'application/crt',
               :body => File.read("/tmp/" + $FileBaseReal + ".ca.crt"),
               :filename => "JN-tls-ca.crt"

    # 附件配置文件
    attachment :content_type => 'application/conf',
               :body => File.read("/tmp/" + $FileBaseReal + ".conf"),
               :filename => "JN-" + $FileBaseUsed + ".conf"

    # VPN密钥
    attachment :content_type => 'application/key',
               :body => File.read("/tmp/" + $FileBaseReal + ".key"),
               :filename => "JN-" + $FileBaseUsed + ".key"

    # VPN证书
    attachment :content_type => 'application/crt',
               :body => File.read("/tmp/" + $FileBaseReal + ".crt"),
               :filename => "JN-" + $FileBaseUsed + ".crt"

  end

=begin
创建FTP账户的邮件通知
=end
  def ftp_email(msg)
    recipients msg[:customer_mail]
    cc msg[:creator_mail]

    from "yuzhili@inspur.com"
    subject "FTP INFORMATION"
    body :msg => msg
    content_type "multipart/mixed"
    part :content_type => "text/plain",
         :body => render(:file => "ftp_email.text.plain.rhtml",
                         :body => body,
                         :layout => 'usermailer.text.plain.erb')
    # part :content_type => "text/html",
    #      :body => render_message("ftp_email.text.html.rhtml", body)
  end

=begin
删除vpn证书的邮件通知
=end
  def vpn_msg_email(user_mail, mail_to, t_create)
    msg = {:user_mail => user_mail, :mail_to => mail_to, :t_create => t_create}
    recipients user_mail
    from "yuzhili@inspur.com"
    subject "VPN CHECK REMINDER"
    body :msg => msg
    content_type "text/html"
    part :content_type => "text/plain",
         :body => render(:file => "vpn_msg_email.text.plain.rhtml",
                         :body => body,
                         :layout => 'usermailer.text.plain.erb')
    # part :content_type => "text/html",
    #      :body => render_message("vpn_msg_email.text.html.rhtml", body)
  end

=begin
删除FTP账户的邮件通知
=end
  def ftp_msg_email(customer_mail, ftpuser)
    msg = {:customer_mail => customer_mail, :ftpuser => ftpuser}
    recipients customer_mail
    from "yuzhili@inspur.com"
    subject "FTP CHECK REMINDER"
    body :msg => msg
    content_type "text/html"
    part :content_type => "text/plain",
         :body => render(:file => "ftp_msg_email.text.plain.rhtml",
                         :body => body,
                         :layout => 'usermailer.text.plain.erb')
    # part :content_type => "text/html",
    #      :body => render_message("ftp_msg_email.text.html.rhtml", body)
  end

end