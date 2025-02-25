class MailSettingsController < ApplicationController
  def index
    @mail_setting = Current.user.mail_setting
    @new_mail_setting = MailSetting.new
  end

  def create
    @mail_setting = Current.user.build_mail_setting(mail_setting_params)
    if @mail_setting.save
      flash[:notice] = "Mail settings saved."
      redirect_to mail_settings_path
    else
      @new_mail_setting = @mail_setting
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @mail_setting = Current.user.mail_setting
    @new_mail_setting = Current.user.mail_setting
    render :index
  end

  def update
    @mail_setting = Current.user.mail_setting
    if @mail_setting.update(mail_setting_params)
      flash[:notice] = "Mail settings updated."
      redirect_to mail_settings_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @mail_setting = Current.user.mail_setting
    @mail_setting.destroy
    flash[:notice] = "Mail settings removed."
    redirect_to mail_settings_path
  end

  private

  def mail_setting_params
    params.require(:mail_setting).permit(:host, :username, :password, :port)
  end
end
