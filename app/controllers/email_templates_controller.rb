class EmailTemplatesController < ApplicationController
  def index
    @email_templates = EmailTemplate.all
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  def create
    @email_template = Current.user.email_templates.build(email_template_params)
    if @email_template.save
      render json: { message: "Email template created." }, status: :created
    else
      render json: { error: @email_template.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
  end

  def draganddrop
  end

  def htmlcode
  end

  private

  def email_template_params
    params.require(:email_templates).permit(:name, :body, :template)
  end
end
