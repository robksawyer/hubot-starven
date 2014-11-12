# Description
#   The latest details about startups and ventures.
#
# Configuration:
#   
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
ChartImage = require('../module/chart_image')

process.env.HUBOT_DATASETS_URL ||= 'https://www.quandl.com/api/v1/datasets/COOLEY/'
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
            
            #Build the data in the chart.js format
            data = 
              labels: rdata.column_names
              datasets: []

            # Compile and format the data
            i = 0
            for result in rdata.data
              data.datasets[i] =
                label: result[0]
                fillColor: "rgba(220,220,220,0.2)",
                strokeColor: "rgba(220,220,220,1)",
                pointColor: "rgba(220,220,220,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(220,220,220,1)",
                data: [ result[1], result[2], result[3], result[4] ]

            # Use the data that was compiled
            msg.send "Please wait a few seconds. Now creating..."
            chart = new ChartImage()
            chart.generate type, data, (err, stdout, stderr) ->
              if err
                msg.send "#{err.name}: #{err.message}"
              filename = encodeURIComponent(chart.filename)
              
              console.log("#{data}")
              
              msg.send "#{robot.helper.url()}/hubot/charts/#{filename}"

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
