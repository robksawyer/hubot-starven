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
quiche = require('quiche') # https://www.npmjs.org/package/quiche
                           
process.env.HUBOT_DATASETS_URL ||= 'https://www.quandl.com/api/v1/datasets/COOLEY/'
process.env.HUBOT_GOOGLE_CHART_URL ||= 'http://chart.googleapis.com/chart?'

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

    data = []

    curDate = new Date()
    curDate.setYear(curDate.getFullYear()-3) # Get the date three years ago
    curDate = curDate.getFullYear() + "-" + curDate.getMonth() + "-" + "01"
    
    console.log(process.env.HUBOT_DATASETS_URL + "VC_VALUE_BY_SERIES.json?trim_start=" + curDate + "&collapse=quarterly");

    robot.http(process.env.HUBOT_DATASETS_URL + "VC_VALUE_BY_SERIES.json?trim_start=" + curDate + "&collapse=quarterly")
       .header('accept', 'application/json')
       .get() (err, res, body) -> 

          if err
            msg.send "Encountered an error :( #{err}"

          if res.statusCode isnt 200
            msg.send "I wasn't able to figure out what the numbers are."
          
          rdata = JSON.parse(body) if body

          if rdata

            # Use the data that was compiled
            #msg.send "Please wait a few seconds. Now creating..."

            formattedData = {}
            formattedData.dates = ( dates[0] for dates in rdata.data)
            formattedData.series_a = (a[1] for a in rdata.data)
            formattedData.series_b = (b[2] for b in rdata.data)
            formattedData.series_c = (c[3] for c in rdata.data)
            formattedData.series_d = (d[4] for d in rdata.data)
            
            theDates = formattedData.dates
            xVals = [theDates[0], theDates[Math.ceil(theDates.length/2)], theDates[theDates.length-1]]
            #theDates = theDates.join(',').replace(/\-/g,'').split(',') # Remove the - so that charts will read as a number

            series_a = formattedData.series_a 
            series_b = formattedData.series_b 
            series_c = formattedData.series_c
            series_d = formattedData.series_d

            rdata.column_names.shift() # Remove Date
            
            chart = quiche('line')
            chart.setTitle(rdata.name);
            chart.setWidth(750);
            chart.setHeight(400);
            chart.addData(series_a.reverse(), rdata.column_names[0], '6899C9');
            chart.addData(series_b.reverse(), rdata.column_names[1], '9E5A8D');
            chart.addData(series_c.reverse(), rdata.column_names[2], '50A450');
            chart.addData(series_d.reverse(), rdata.column_names[3], 'E57F3C');
            chart.addAxisLabels('x', xVals.reverse());
            chart.setAutoScaling();
            #chart.setTransparentBackground();
            imageUrl = chart.getUrl(false)

            # url = process.env.HUBOT_GOOGLE_CHART_URL + chartArgs.join('&') + '#.png'
            msg.send '#{imageUrl}#.png'
            msg.send rdata.description

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
