class Api::V1::QuestionsController < ApplicationController
  def ask
    @question = Ask.new(prams[:query]).call
    render json: @question
  end
end
