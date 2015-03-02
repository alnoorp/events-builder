require_relative 'env'
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'rest-client'
require 'json'
require 'pry'

class MySinatraApp < Sinatra::Base

  CLIENT_ID = ENV['CLIENT_ID']
  CLIENT_SECRET = ENV['CLIENT_SECRET']
  REDIRECT_URI = 'http://localhost:9292/oauth/callback' if Sinatra::Base.development?
  REDIRECT_URI = 'https://events-builder.herokuapp.com/oauth/callback' if Sinatra::Base.production?

  get '/' do
    erb :index, locals: {
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT_URI,
    }
  end

  get '/oauth/callback' do
    # ACCESS_TOKEN = request.env['rack.request.query_hash']['access_token']
    REFRESH_TOKEN = request.env['rack.request.query_hash']['refresh_token']
    url = 'https://api.hubapi.com/auth/v1/refresh?refresh_token=' + REFRESH_TOKEN + '&client_id=' + CLIENT_ID + '&grant_type=refresh_token'
    refresh = RestClient.post url, '', content_type: 'application/x-www-form-urlencoded'
    parsed = JSON.parse(refresh)
    PORTAL_ID = parsed['portal_id']
    ACCESS_TOKEN = parsed['access_token']
    REFRESH_TOKEN = parsed['refresh_token']
    redirect '/app'
  end

  get '/contacts' do
    RestClient.get 'http://api.hubapi.com/contacts/v1/lists/all/contacts/all',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
  end

  get '/updated' do
    RestClient.get 'https://api.hubapi.com/contacts/v1/lists/recently_updated/contacts/recent',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
  end

  get '/blogs' do
    RestClient.get 'https://api.hubapi.com/content/api/v2/blogs',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
  end

  get '/workflows' do
    RestClient.get 'https://api.hubapi.com/automation/v2/workflows',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
  end

  get '/properties' do
    RestClient.get 'https://api.hubapi.com/contacts/v1/properties',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
  end

  get '/app' do

    has_more = true
    vid_offset = '0'
    contacts_data_array = []

    until has_more == false

    contacts = RestClient.get 'http://api.hubapi.com/contacts/v1/lists/all/contacts/all',
      params: { access_token: ACCESS_TOKEN, vidOffset: vid_offset }, content_type: 'application/json'

    contacts_output = JSON.parse(contacts)
    has_more = contacts_output['has-more']
    vid_offset = contacts_output['vid-offset'].to_s

      contacts_output['contacts'].each do |item|
        contacts_data = {}

        item['identity-profiles'].first['identities'].each do |id|
          if id['type'] == 'EMAIL'
            contacts_data['email'] = id['value']
          end
        end

        if item['properties']['firstname']
          contacts_data['firstname'] = item['properties']['firstname']['value']
        else
          contacts_data['firstname'] = ''
        end
        if item['properties']['lastname']
          contacts_data['lastname'] = item['properties']['lastname']['value']
        else
          contacts_data['lastname'] = ''
        end

        contacts_data['label'] = contacts_data['email'].to_s + ' -- ' + contacts_data['firstname'] + ' ' + contacts_data['lastname']
        contacts_data_array << contacts_data
      end

    end

    properties = RestClient.get 'https://api.hubapi.com/contacts/v1/properties',
      params: { access_token: ACCESS_TOKEN }, content_type: 'application/json'
    properties_output = JSON.parse(properties)
    properties_data = {}
    properties_output.each do |item|
      properties_data[item['label']] = item['name'] if item['formField']
    end

    erb :app, locals: {
      properties_data: properties_data,
      portal_id: PORTAL_ID,
      contacts_data_array: contacts_data_array
    }
  end
end
