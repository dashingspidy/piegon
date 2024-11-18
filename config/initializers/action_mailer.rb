options = { region: "us-east-1" }
ActionMailer::Base.add_delivery_method :ses, Aws::Rails::SesMailer, **options
