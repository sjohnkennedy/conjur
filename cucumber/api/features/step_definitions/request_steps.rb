# frozen_string_literal: true

Given(/^I authorize the request with the host factory token$/) do
  expect(@host_factory_token).to be
  headers[:authorization] = %Q(Token token="#{@host_factory_token.token}")
end

Given(/^I set the "([^"]*)" header to "([^"]*)"$/) do |header, value|
  headers[header] = value
end

When(/^I( (?:can|successfully))? GET "([^"]*)"$/) do |can, path|
  try_request can do
    get_json path
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)"$/) do |can, path|
  try_request can do
    put_json path
  end
end

# TODO: Remove the hack to avoid ambiguous match with one below it
When('I do DELETE "\/host_factory_tokens\/{host_factory_token}"') do |hf|
  try_request true do
    delete_json "/host_factory_tokens/#{hf}"
  end
end

# TODO: Remove the hack to avoid ambiguous match with one below it
When('I try to DELETE "\/host_factory_tokens\/{host_factory_token}"') do |hf|
  try_request false do
    delete_json "/host_factory_tokens/#{hf}"
  end
end

When(/^I( (?:can|successfully))? DELETE "([^"]*)"$/) do |can, path|
  try_request can do
    delete_json path
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with authorized user$/) do |can, path|
  try_request can do
    get_json path, token: ConjurToken.new(@response_body)
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with parameters:$/) do |can, path, parameters|
  params = YAML.load(parameters)
  path = [ path, params.to_query ].join("?")
  try_request can do
    get_json path
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with(?: username "([^"]*)" and password "([^"]*)")?(?: and)?(?: plain text body "([^"]*)")?$/) do |can, path, username, password, body|
  try_request can do
    put_json path, body, user: username, password: password
  end
end

When(/^I( (?:can|successfully))? GET "([^"]*)" with username "([^"]*)" and password "([^"]*)"$/) do |can, path, username, password|
  try_request can do
    get_json_with_basic_auth(path, user: username, password: password)
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with body from file "([^"]*)"/) do |can, path, filename|
  absolute_path = "#{File.dirname __FILE__}/../support/#{filename}"
  File.open(absolute_path) do |file|
    try_request can do
      post_json path, file.read
    end
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with in-body params$/) do |can, path|
  try_request can do
    post_multipart_json path
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with body from file "([^"]*)"/) do |can, path, filename|
  absolute_path = "#{File.dirname __FILE__}/../support/#{filename}"
  File.open(absolute_path) do |file|
    try_request can do
      post_json path, file.read
    end
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)"(?: with plain text body "([^"]*)")?$/) do |can, path, body|
  try_request can do
    post_json path, body
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with body:$/) do |can, path, body|
  try_request can do
    post_json path, body
  end
end

When(/^I( (?:can|successfully))? PUT "([^"]*)" with body:$/) do |can, path, body|
  try_request can do
    put_json path, body
  end
end

When(/^I( (?:can|successfully))? PATCH "([^"]*)" with body:$/) do |can, path, body|
  try_request can do
    patch_json path, body
  end
end

When(/^I( (?:can|successfully))? POST "([^"]*)" with parameters:$/) do |can, path, parameters|
  params = YAML.load(parameters)
  try_request can do
    post_json path, params
  end
end

When(/^I( ?:can|successfully)? authenticate as "([^"]*)" with account "([^"]*)"/) do |can, login, account|
  user = lookup_user(login, account)
  user.reload

  try_request can do
    post_json "/authn/#{account}/#{login}/authenticate", user.api_key
  end
end

Then(/^the result is an API key$/) do
  expect(@result).to be
  expect(@result.length).to be > 40
  expect(@result).to match(/^[a-z0-9]+$/)
end

Then(/^the result is the API key for user "([^"]*)"$/) do |login|
  user = lookup_user(login)
  user.reload
  expect(user.credentials).to be
  expect(@result).to eq(user.credentials.api_key)
end

Then(/^it's confirmed$/) do
  expect(@status).to be_blank
end

Then(/^the HTTP response status code is (\d+)$/) do |code|
  expect(@status).to eq(code.to_i)
end

Then(/^the HTTP response content type is "([^"]*)"$/) do |content_type|
  expect(@content_type).to match(content_type)
end

Then(/^the result is true$/) do
  expect(@result).to be true
end

Then(/^the result is false$/) do
  expect(@result).to be false
end

Then(/^I (?:can )*authenticate with the admin API key for the account "(.*?)"/) do |account|
  user = lookup_user('admin', account)
  user.reload
  steps %Q{
    Then I can POST "/authn/#{account}/admin/authenticate" with plain text body "#{user.api_key}"
  }
  steps %Q{
    And I can GET "/authn/#{account}/login" with username "admin" and password "#{user.api_key}"
  }
end

Then(/^I save the response as "(.+)"$/) do |name|
  @saved_results = @saved_results || {}
  @saved_results[name] = @result
end

# TODO: is it right place?  This is ugly right now...
# TODO: the host factory and other concern need to be split apart
Then("our JSON should be:") do |json|
  @result.delete('created_at')
  if @response_api_key
    json = json.gsub("@response_api_key@", @response_api_key)
  end
  json = render_hf_token_and_expiration(json)
  expect(@result).to eq(JSON.parse(json))
end

# TODO: we need a better refactoring for this
Then("the host factory JSON should be:") do |json|
  @result.delete('created_at')
  token = @result.dig('tokens', 0)
  if token
    json = json.gsub("@host_factory_token@", token['token'])
    json = json.gsub(
      "@host_factory_token_expiration@",
      parse_expiration(token['expiration'])
    )
  end
  expect(@result).to eq(JSON.parse(json))
end
