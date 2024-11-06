class EmailTemplatesController < ApplicationController
  def index
    @email_templates = EmailTemplate.all
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  def create
  end

  def destroy
  end

  def draganddrop
  end

  def htmlcode
  end

  def tiptapeditor
  end
end
