if Rails.env.development? || Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :user_name            => ENV['gmail_username'],
    :password             => ENV['gmail_password'],
    :domain               => 'international-shipping-service.herokuapp.com',
    :authentication       => "plain",
    :enable_starttls_auto => true,
    :openssl_verify_mode  => 'none'
  }

end
