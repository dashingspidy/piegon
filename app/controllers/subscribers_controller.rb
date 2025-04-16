require "csv"
class SubscribersController < ApplicationController
  allow_unauthenticated_access only: :embed
  skip_before_action :verify_authenticity_token, only: :embed
  include Pagy::Backend
  before_action :set_contact, except: :embed

  def index
    subscriber_scope = @contact.subscribers.subscribed
    if Current.user.plan == "free"
      subscriber_scope = subscriber_scope.limit(100)
    end
    @pagy, @subscribers = pagy(subscriber_scope)
    @csv_upload = CsvUploader.new
    if @contact.csv_uploader
      @contact.csv_uploader.csv_file.open do |temp|
        @headers = CSV.foreach(temp, headers: false).first
      end
    end
    @columns = Subscriber.column_names - [ "id", "created_at", "updated_at", "contact_id" ]
    @api_token = @contact.api_token
  end

  def upload
    @csv_upload = @contact.build_csv_uploader(params.require(:csv_uploader).permit(:csv_file))
    if @csv_upload.save
      @csv_upload.csv_file.open do |temp|
        @headers = CSV.foreach(temp, headers: false).first
      end
      @columns = Subscriber.column_names - [ "id", "created_at", "updated_at", "contact_id", "unsubscribed" ]
      render turbo_stream: turbo_stream.replace(
        "modal_form_content",
        partial: "subscribers/column_mapping_content"
      )
    else
      render turbo_stream: turbo_stream.replace(
        "modal_form_content",
        partial: "subscribers/csv_upload_modal_content"
      )
    end
  end

  def parse_csv
    column_mapping = params["column_mapping"].to_unsafe_h
    if column_mapping.present?
      CsvImportJob.perform_later(@contact.id, column_mapping)
      render turbo_stream: [
        turbo_stream.replace(
          "modal_form_content",
          partial: "subscribers/success_message"
        )
      ]
    else
      render turbo_stream: turbo_stream.replace(
        "modal_form_content",
        partial: "subscribers/column_mapping_content",
        locals: { headers: @headers, columns: @columns }
      )
    end
  end

  def embed
    @contact = Contact.find_by(api_token: params[:api_token])
    @contact.subscribers.build(subscribers_params)
    if @contact.save
      render json: { message: "Successfully" }, status: :created
    else
      render json: { error: @contact.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.subscribers.find(params[:id]).delete
    redirect_to contact_subscribers_path(@contact)
  end

  private

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def subscribers_params
    params.require(:subscriber).permit(:email)
  end
end
