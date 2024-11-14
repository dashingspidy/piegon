class EmailTemplatesController < ApplicationController
  def index
    @email_templates = EmailTemplate.all
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  def new
    @email_template = EmailTemplate.new
  end

  def create
    @email_template = Current.user.email_templates.build(email_template_params)
    if @email_template.save
      respond_to do |format|
        format.html { redirect_to email_templates_path }
        format.json
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: @email_template.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  def draganddrop
  end

  private

  def email_template_params
    params.require(:email_template).permit(:name, :body, :template)
  end
end
