# Description:
# Returns a random stock photo via getty connect based on keywords
# or inlines a specific stock photo via the file id (eg 103332443)
#
# Dependencies:
# None
#
# Configuration:
# HUBOT_GETTY_CONNECT_API_KEY
#
# Commands:
# hubot get(ty) me <search query|file id> 
#
# Author:
# brianvans@gmail.com

module.exports = (robot) ->
  # get api key from environment
  apikey = process.env.HUBOT_GETTY_CONNECT_API_KEY
  uri = "https://connect.gettyimages.com/v3"

  robot.respond /(getty|get) me (.*)/i, (msg) ->
    user = msg.message.user.name
    if /^[0-9]+$/.test(msg.match[2]) # check if the query was an image id
      search_query = "/images/#{msg.match[2]}?fields=thumb"
    else
      search_query = "/search/images?phrase=#{msg.match[2]}&fields=thumb&page=1&page_size=100"

    try
      msg.http(uri + search_query)
        .headers("Content-Type": "application/json", "Api-Key": apikey)
        .get() (err, res, body) ->
          switch res.statusCode
            when 200
              try
                parsed_response = JSON.parse(body)
              catch error
                msg.send "Error parsing getty connect api response"
              if parsed_response.images.length > 0
                rand = Math.floor(Math.random() * (parsed_response.images.length))
                msg.send parsed_response.images[rand].display_sizes[0].uri
              else
                msg.send "No results found for #{msg.match[2]} (sadpanda)"
            else
              msg.send "Error in getty connect api call"
    catch error
      msg.send "Error hitting getty connect. Service down?"
