class ApplicationController < Monkeybars::Controller
  # Add content here that you want to be available to all the controllers
  # in your application
  APP_HEIGHT_FUDGE         ||= 65
  APP_MENU_HEIGHT          ||= 20
  APP_STATUS_HEIGHT        ||= 40
  APP_WIDTH_FUDGE          ||= 20
  APP_SCROLLBAR_WIDTH      ||= 20
  APP_SCROLLBAR_HEIGHT     ||= 20
  APP_SCREEN_REMAIN_WIDTH  ||= 40
  APP_SCREEN_REMAIN_HEIGHT ||= 40
end