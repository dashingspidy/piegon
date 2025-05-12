class TicketsController < ApplicationController
  def index
    @tickets = Current.user.tickets
  end

  def show
    @ticket = Current.user.tickets.find(params[:id])
    @replies = @ticket.replies
  end

  def new
    @ticket = Current.user.tickets.new
  end

  def create
    @ticket = Current.user.tickets.new(ticket_params)
    if @ticket.save
      redirect_to tickets_path, notice: "Support ticket created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def reply
    @ticket = Current.user.tickets.find(params[:ticket_id])
    @reply = @ticket.replies.new(description: params[:description], user_id: Current.user.id)

    if @reply.save
      redirect_to @ticket, notice: "Reply was added successfully."
    else
      @replies = @ticket.replies.where.not(id: @reply.id)
      flash.now[:alert] = "Reply couldn't be saved. Please try again."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def ticket_params
    params.expect(ticket: [ :subject, :description, :finished ])
  end
end
