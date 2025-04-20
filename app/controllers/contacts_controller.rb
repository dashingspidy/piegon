class ContactsController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :require_payment, only: %i[new create]
  def index
    @contacts = Current.user.contacts
  end

  def new
    @contact = Current.user.contacts.new
  end

  def create
    @contact = Current.user.contacts.build(contact_params)
    if @contact.save
      redirect_to contacts_path, notice: "New contact list created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :url)
  end
end
