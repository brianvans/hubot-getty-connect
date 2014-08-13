# Description:
# Returns a random stock photo via getty connect based on keywords
# or inlines a specific stock photo via the file id (eg 103332443)
#
# Dependencies:
# None
#
# Configuration:
# HUBOT_GETTY_CONNECT_SYSTEM_ID
# HUBOT_GETTY_CONNECT_SYSTEM_PASSWORD
# HUBOT_GETTY_CONNECT_USER_NAME
# HUBOT_GETTY_CONNECT_USER_PASSWORD
#
# Commands:
# hubot get(ty) me <search query|file id> 
#
# Author:
# brianvans@gmail.com

module.exports = (robot) ->
  # get some parameters for authentication
  systemid       = process.env.HUBOT_GETTY_CONNECT_SYSTEM_ID
  systempassword = process.env.HUBOT_GETTY_CONNECT_SYSTEM_PASSWORD
  username       = process.env.HUBOT_GETTY_CONNECT_USER_NAME
  password       = process.env.HUBOT_GETTY_CONNECT_USER_PASSWORD

  robot.respond /(getty|get) me (.*)/i, (msg) ->
    auth_params = {
      "RequestHeader":{
        "Token":""
      },
      "CreateSessionRequestBody":{
        "SystemId":"#{systemid}",
        "SystemPassword":"#{systempassword}",
        "UserName":"#{username}",
        "UserPassword":"#{password}"
      }
    }
    apiCall msg, 'v1/session/CreateSession', auth_params, (auth_response) ->
      try 
        token = auth_response.CreateSessionResult.Token
      catch error
        msg.send "Error with your getty connect credentials"
        return

      if /^[0-9]+$/.test(msg.match[2]) # check if the query was an image id
        search_params = {
          "RequestHeader":{
            "Token":"#{token}"
          },
          "GetImageDetailsRequestBody":{
            "CountryCode": "USA",
            "ImageIds": ["#{msg.match[2]}"]
          }
        }
        apiCall msg, 'v1/search/GetImageDetails', search_params, (search_response) ->
          if search_response.GetImageDetailsResult.Images[0]
            msg.send search_response.GetImageDetailsResult.Images[0].UrlWatermarkPreview
          else
            msg.send "No results found for image id #{msg.match[2]} (sadpanda)"
            return
      else
        search_params = {
          "RequestHeader":{
            "Token":"#{token}"
          },
          "SearchForImages2RequestBody":{
            "Query":{
              "SearchPhrase":"#{msg.match[2]}"
            },
            "ResultOptions":{
              "ItemCount":"25",
              "ItemStartNumber":"1"
            }
          },
        }
        apiCall msg, 'v1/search/SearchForImages', search_params, (search_response) ->
          if search_response.SearchForImagesResult.ItemCount > 0
            rand = Math.floor(Math.random() * (search_response.SearchForImagesResult.ItemCount))
            msg.send search_response.SearchForImagesResult.Images[rand].UrlWatermarkPreview
          else
            msg.send "No results found (sadpanda)"
 
  # function for making getty connect api calls.
  apiCall = (msg, endpoint, params, handler) ->
    stringParams = JSON.stringify params
    try
      msg.http("https://connect.gettyimages.com/#{endpoint}")
        .headers("Content-Length": stringParams.length, "Content-Type": "application/json")
        .post(stringParams) (err, res, body) ->
          switch res.statusCode
            when 200
              try
                handler(JSON.parse(body))
              catch error
                msg.send "Error parsing getty connect api response"
            else
              msg.send "Error in getty connect api call"
    catch error
      msg.send "Error POSTing to getty connect. Service down?"
