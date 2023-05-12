class Api::V1::QuestionsController < ApplicationController
  def ask
    @question = Ask.new(params[:query]).call
    render json: { answer: @question.answer }
  end
end
