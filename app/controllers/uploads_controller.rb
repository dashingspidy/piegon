class UploadsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    file = params[:file]

    if file.present?
      # Create a blob and get the direct URL
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      )

      # Generate a URL that can be accessed directly
      url = Rails.application.routes.url_helpers.url_for(blob)

      render json: { filelink: url }, status: :ok
    else
      render json: { error: "No file provided" }, status: :unprocessable_entity
    end
  end
end
