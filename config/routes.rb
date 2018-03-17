Rails.application.routes.draw do
  root 'welcome#index'

  get 'welcome/index'

  post 'welcome/results', to:"welcome#results" , as:"results"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
