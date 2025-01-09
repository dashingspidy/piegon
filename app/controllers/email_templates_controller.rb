class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: [ :show, :edit, :update ]
  def index
    @email_templates = Current.user.email_templates
  end

  def show
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

  def edit
  end

  def update
    if @email_template.update(email_template_params)
      respond_to do |format|
        format.html { redirect_to email_templates_path }
        format.json
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: @email_template.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  def draganddrop
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:name, :body, :template, :editor)
  end
end
