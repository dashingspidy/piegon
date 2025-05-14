class EmailTemplatesController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :require_payment, only: %i[new create]
  before_action :require_paid_plan, only: %i[draganddrop]
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
      pluginId: "ebc379f90a5f4440a3bb66a42c7fe420",
      secretKey: "9aebba8862fd4fe68c45a108aa5570a7",
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

  def require_paid_plan
    return unless authenticated?
    if Current.user.plan == "free"
      redirect_to email_templates_path, alert: "Drag and drop editor is not available on the Free plan. Please upgrade to access this feature."
    end
  end
end
