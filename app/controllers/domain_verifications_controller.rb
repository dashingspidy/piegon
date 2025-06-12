class DomainVerificationsController < ApplicationController
  before_action :set_domain_verification, only: [ :show, :verify, :destroy, :check_status ]
  before_action :authenticate_user!
  before_action :check_confirmed_user, only: [ :new, :create, :verify ]

  def index
    @domain_verifications = Current.user.domain_verifications.order(created_at: :desc)
  end

  def show
  end

  def new
    @domain_verification = Current.user.domain_verifications.build
  end

  def create
    @domain_verification = Current.user.domain_verifications.build(domain_verification_params)

    if @domain_verification.save
      if @domain_verification.create_sendgrid_domain
        redirect_to @domain_verification, notice: "Domain verification created successfully. Please add the DNS records to verify your domain."
      else
        error_message = @domain_verification.last_error || "Unknown SendGrid API error"
        redirect_to @domain_verification, alert: "Domain was saved but failed to create in SendGrid: #{error_message}"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def verify
    if @domain_verification.verify_domain
      redirect_to @domain_verification, notice: "Domain verified successfully!"
    else
      redirect_to @domain_verification, alert: "Domain verification failed. Please ensure DNS records are properly configured."
    end
  end

  def check_status
    @domain_verification.check_verification_status
    redirect_to @domain_verification, notice: "Domain status updated."
  end

  def destroy
    # Delete from SendGrid first if it exists
    if @domain_verification.sendgrid_domain_id.present?
      SendgridService.new.delete_domain(@domain_verification.sendgrid_domain_id)
    end

    @domain_verification.destroy
    redirect_to domain_verifications_path, notice: "Domain verification deleted successfully."
  end

  private

  def set_domain_verification
    @domain_verification = Current.user.domain_verifications.find(params[:id])
  end

  def domain_verification_params
    params.require(:domain_verification).permit(:domain)
  end

  def authenticate_user!
    redirect_to new_session_path unless Current.user
  end
end
