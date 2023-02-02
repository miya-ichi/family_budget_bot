class Admin::ExpensesController < ApplicationController
  before_action :basic_auth

  def index
    @expenses = Expense.all
  end

  def new
    @expense = Expense.new
  end

  def create
    @expense = Expense.new(expense_params)
    @expense.paid = false
    @expense.line_user_id = 'admin'

    if @expense.save
      redirect_to admin_expenses_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @expense = Expense.find(params[:id])
  end

  def update
    @expense = Expense.find(params[:id])

    if @expense.update(expense_params)
      redirect_to admin_expenses_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense = Expense.find(params[:id])

    @expense.destroy
    redirect_to admin_expenses_url, status: :see_other
  end

  private

  def expense_params
    params.require(:expense).permit(:name, :cost, :paid, :line_user_id)
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == Rails.application.credentials.basic_auth_params[:user_name] && password == Rails.application.credentials.basic_auth_params[:password]
    end
  end
end
