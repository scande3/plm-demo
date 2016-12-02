Rails.application.routes.draw do
  mount Mei::Engine => '/'

  
  mount Blacklight::Engine => '/'
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users, :controllers => { registrations: 'registrations' }
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  #  Super barebones report page to show the difference
  get 'reports' => 'reports#index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
