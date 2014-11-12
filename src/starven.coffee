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
Quiche = require('quiche') # https://www.npmjs.org/package/quiche
                           
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
    curDate.setYear(curDate.getYear()-3) # Get the date three years ago
    curDate = curDate.getFullYear() + "-" + curDate.getMonth() + "-" + "01"

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
            msg.send "Please wait a few seconds. Now creating..."

            formattedData = {}
            formattedData.dates = ( dates[0] for dates in rdata.data)
            formattedData.series_a = (a[1] for a in rdata.data)
            formattedData.series_b = (b[2] for b in rdata.data)
            formattedData.series_c = (c[3] for c in rdata.data)
            
            theDates = formattedData.dates
            xVals = [theDates[theDates.length-1], theDates[0]]
            theDates = theDates.join(',').replace(/\-/g,'').split(',') # Remove the - so that charts will read as a number

            series_a = [ theDates, formattedData.series_a ]
            #series_b = [ theDates, formattedData.series_b ]
            #series_c = [ theDates, formattedData.series_c ]
            
            #theDates = [ theDates[0], theDates[Math.ceil(theDates.length/2)], theDates[theDates.length] ]

            rdata.column_names.shift() # Remove Date
            
            # chartArgs = []
            # datePart = []
            # datePart.push encodeURIComponent(rdata.from_date)
            # datePart.push 'to'
            # datePart.push encodeURIComponent(rdata.to_date)
            # chartArgs.push 'chtt=' +  encodeURIComponent(rdata.name)                                      # Chart title
            # #chartArgs.push 'chts=000000,14'                                                              # <color>,<font_size>, <opt_alignment>
            # chartArgs.push 'chs=750x400'                                                                  # <width>x<height>
            # chartArgs.push 'cht=lxy'                                                                      # Chart type
            # chartArgs.push 'chdl=' + rdata.column_names.join("|")                                         # Chart legend text and style <data_series_1_label>|...|<data_series_n_label>
            # chartArgs.push 'chdlp=t'                                                                      # <opt_position>|<opt_label_order>
            # chartArgs.push 'chco=0000FF,FF0000,FFFF00,00FF00'                                             # Series colors <color_1>, ... <color_n>
            # chartArgs.push 'chxt=x,y'                                                                     # Axis styles and labels
            # #chartArgs.push 'chxl=0:|' + xVals.join("|")                                                   # Custom axis label
            # #chartArgs.push 'chxp=0,0'                                                                     # Label location
            # chartArgs.push 'chd=t:' + series_a.join("|")                                                  # The data

            chart = quiche('line')
            chart.setTitle('Something with lines');
            chart.addData([3000, 2900, 1500], 'Blah', '008000');
            chart.addData([1000, 1500, 2000], 'Asdf', '0000FF');
            chart.addAxisLabels('x', ['1800', '1900', '2000']);
            chart.setAutoScaling();
            chart.setTransparentBackground();
            imageUrl = chart.getUrl(true)
            
            url = process.env.HUBOT_GOOGLE_CHART_URL + chartArgs.join('&') + '#.png'
            msg.send imageUrl 
            msg.send '\n-\n' + rdata.description

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
