class ApplicationController < ActionController::Base
  before_filter :set_locale

  def set_locale
    I18n.locale = 'en_EU'
  end
end
