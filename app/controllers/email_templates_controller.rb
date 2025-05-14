class EmailTemplatesController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :require_payment, only: %i[new create draganddrop]
  before_action :set_email_template, only: [ :show, :edit, :update, :destroy ]
  skip_before_action :verify_authenticity_token, only: [ :token ]
  layout "editor_only", only: [ :draganddrop ]
  def index
    @email_templates = Current.user.email_templates
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: { html: @email_template.html, css: @email_template.css, name: @email_template.name } }
    end
  end

  def new
    @email_template = EmailTemplate.new
  end

  def create
    @email_template = Current.user.email_templates.build(email_template_params)
    if @email_template.save
      respond_to do |format|
        format.html {
          redirect_to email_templates_path, notice: "Email template created successfully"
        }
        format.json {
          render json: { redirect_url: email_templates_path, notice: "Email template created successfully" }
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { alert: @email_template.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: { html: @email_template.html, css: @email_template.css, name: @email_template.name } }
    end
  end

  def update
    if @email_template.update(email_template_params)
      respond_to do |format|
        format.html {
          redirect_to email_templates_path, notice: "Email template updated successfully"
        }
        format.json {
          render json: { redirect_url: email_templates_path, notice: "Email template updated successfully" }
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { alert: @email_template.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @email_template.destroy
    redirect_to email_templates_path, notice: "Email template successfully deleted."
  end

  def draganddrop
  end

  def token
    payload = {
      pluginId: "f7c28edf9b7a4f87b185881780ca6e14",
      secretKey: "c494ee43e32b4df3a3a278b88a3d6682",
      userId: 1,
      role: "user"
    }

    response = Net::HTTP.post(
      URI("https://plugins.stripo.email/api/v1/auth"),
      payload.to_json,
      { "Content-Type" => "application/json" }
    )

    if response.code == "200"
      render json: { token: JSON.parse(response.body)["token"] }
    else
      render json: { error: "Failed to authenticate with Stripo" }, status: :unprocessable_entity
    end
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:name, :body, :template, :editor, :html, :css)
  end
end
