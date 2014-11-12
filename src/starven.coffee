# Description
#   The latest details about startups and ventures.
#
# Configuration:
#   
# Dependencies:
#   "chart.js": "^1.0.1-beta.2"
#   "phantomjs": "^1.9.12"
#   
# Commands:
#   hubot startup valuations - Pulls the latest startup valuations
#
# Notes:
#  
#
# Author:
#   robksawyer[@<org>]

fs   = require('fs')
path = require('path')
events = require('events')
# ChartImage = require('../module/chart_image')

process.env.HUBOT_DATASETS_URL ||= 'https://www.quandl.com/api/v1/datasets/COOLEY/'
process.env.HUBOT_GOOGLE_CHART_URL ||= 'https://www.google.com/jsapi'
process.env.HUBOT_DEFAULT_CHART_TYPE ||= 'line'

module.exports = (robot) ->

  robot.helper =
    url: () ->
      server = robot.server.address()
      process.env.HEROKU_URL ? "http://#{server.address}:#{server.port}"

  robot.respond /hello/i, (msg) ->
    msg.reply "hello!"

  #
  # Startup Valuations
  # Startup financing is typically done in several rounds, as the startup company grows and its capital needs evolve. The first institutional round is 
  # usually called the "Series A round". Later rounds are called Series B, C, D, etc.
  #
  robot.respond /startup (valuations|vals)/i, (msg) ->

    robot.http(process.env.HUBOT_GOOGLE_CHART_URL)
      .get() (err, res, body) ->

        vm.runInThisContext( body, 'remote/jsapi.js' ); 

        google.load('visualization', '1', {
          packages: ['corechart']
        });

        data = []

        robot.http(process.env.HUBOT_DATASETS_URL + "VC_VALUE_BY_SERIES.json")
           .header('accept', 'application/json')
           .get() (err, res, body) -> 

              if err
                msg.send "Encountered an error :( #{err}"

              if res.statusCode isnt 200
                msg.send "I wasn't able to figure out what the numbers are."
              
              rdata = JSON.parse(body) if body

              if rdata

                #The chart type to build
                type = process.env.HUBOT_DEFAULT_CHART_TYPE
                
                chart = new google.visualization.LineChart()

                #Build the data in the chart.js format
                data = [
                  rdata.column_names,
                  rdata.data
                ]

                # Use the data that was compiled
                msg.send "Please wait a few seconds. Now creating..."

                # msg.send data
                chart.draw(data, options);

                chartImage = chart.getImageURI()
                
                msg.reply chartImage

              else 

                msg.send "The dataset was too confusing, so I gave up."


  # 
  # Get an image from `/tmp` dir
  # 
  robot.router.get "/hubot/charts/:key", (req, res) ->
      tmp = path.join(__dirname, '..', 'tmp', req.params.key)
      fs.exists tmp, (exists) ->
        if exists
          fs.readFile tmp,(err,data) ->
            res.writeHead(200, { 'Content-Type': 'image/png' })
            res.end(data)
        else
          res.status(404).send('Not found')
