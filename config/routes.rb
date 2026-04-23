Rails.application.routes.draw do
  root "ship_window_managers#show"
  resource :ship_window_manager, only: [:show, :update]
end

