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
