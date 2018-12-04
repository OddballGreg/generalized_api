# frozen_string_literal: true

Rails.application.routes.draw do
  mount GeneralizedApi::Engine => "/generalized_api"

  post "tests/search", to: "tests#search"
  post "tests/query", to: "tests#index"
  resources :tests

  post "blocks/search", to: "blocks#search"
  post "blocks/query", to: "blocks#index"
  resources :blocks

  post "customers/search", to: "customers#search"
  post "customers/query", to: "customers#index"
  resources :customers

  post "module/:model/search", to: "module_api#search"
  post "module/:model/query", to: "module_api#index"
  post "module/:model/query/count", to: "module_api#count"
  post "module/:model", to: "module_api#create"
  put "module/:model/:id", to: "module_api#update"
  patch "module/:model/:id", to: "module_api#update"
  delete "module/:model/:id", to: "module_api#destroy"
  get "module/:model/:id", to: "module_api#show"
  get "module/:model", to: "module_api#index"
  get "module/:model/count", to: "module_api#count"

  post "class/:model/search", to: "class_api#search"
  post "class/:model/query", to: "class_api#index"
  post "class/:model/query/count", to: "class_api#count"
  post "class/:model", to: "class_api#create"
  put "class/:model/:id", to: "class_api#update"
  patch "class/:model/:id", to: "class_api#update"
  delete "class/:model/:id", to: "class_api#destroy"
  get "class/:model/:id", to: "class_api#show"
  get "class/:model", to: "class_api#index"
  get "class/:model/count", to: "class_api#count"
end
