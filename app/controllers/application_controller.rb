class ApplicationController < ActionController::Base
  # turning off csfr for now.
  protect_from_forgery with: :null_session
end
