require 'faraday'
require 'json'
require 'rubygems'

class HomeController < ApplicationController

  def home
    render :layout => false
  end

  def index
    @id = params['obj']['_id']
    @access_token = params['auth']['access_token']

    puts 'start here'
    conn = Faraday.new(:ssl => {:verify => false})
    response = conn.post do |req|
      req.url 'https://api.getemailbox.com/api/search'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.body = '{
                      "auth": {
                          "app": "pkg.dev.readability",
                          "access_token": "' + @access_token + '"
                      },
                      "data": {
                          "model": "Email",
                          "conditions": {
                              "_id": "' + @id + '"
                          },
                          "fields": ["original.ParsedData"],
                          "limit": 1,
                          "sort": {
                              "_id": -1
                          }
                      }
                  }'
    end

    text = JSON.parse(response.body)["data"][0]["Email"]["original"]["ParsedData"][0]["Data"]
    words = text.split(" ")
    length = words.length
    minutes = length/180.0

    if minutes > 10
      @readability = "Over 10 minutes"
    elsif minutes > 5
      @readability = "5-10 minutes"
    elsif minutes > 1
      @readability = "1-5 minutes"
    else
      @readability = "Under 1 minute"
    end

    response = conn.post do |req|
      req.url 'https://api.getemailbox.com/api/event'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.body = '{
                      "auth": {
                          "app": "pkg.dev.readability",
                          "access_token": "' + @access_token + '"
                      },
                      "data": {
                          "event": "Email.action",
                          "obj": {
                            "_id": "' + @id + '",
                            "action": "label",
                            "label": "' + @readability + '"
                          }
                      }
                  }'
    end
    puts "this is the event response"
    puts JSON.parse(response.body)


    render text: @id



  end
end

