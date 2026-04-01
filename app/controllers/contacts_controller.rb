class ContactsController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :set_contact, only: %i[edit update destroy]
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

  def edit
    @contact = Current.user.contacts.find(params[:id])
  end

  def update
    @contact = Current.user.contacts.find(params[:id])
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "Contact list updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      @contact.destroy
      redirect_to contacts_path, notice: "Contact list and all associated data deleted successfully."
    rescue ActiveRecord::RecordNotDestroyed
      redirect_to contacts_path, alert: "Unable to delete contact list. It may have associated campaigns or subscribers."
    rescue ActiveRecord::InvalidForeignKey
      redirect_to contacts_path, alert: "Cannot delete contact list because it has associated campaigns or subscribers."
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :url)
  end

  def set_contact
    @contact = Current.user.contacts.find(params[:id])
  end
end
