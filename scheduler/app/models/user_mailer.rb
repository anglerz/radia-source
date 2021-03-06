class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = url_for(:host => 'source.radiozero.pt', :controller => 'users', :action => 'activate', :activation_code => "#{user.activation_code}")
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = url_for(:host => 'source.radiozero.pt', :controller => 'sessions', :action => 'new')
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "no-reply@radiozero.pt"
      @subject     = "[Rádio Zero] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
