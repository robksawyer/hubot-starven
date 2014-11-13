# Description
#   The latest details about angel and venture investment, plus information related to starting a company.
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

quiche = require('quiche') # https://www.npmjs.org/package/quiche
gShort = require('short-url') # https://www.npmjs.org/package/short-url

process.env.HUBOT_DATASETS_URL ||= 'https://www.quandl.com/api/v1/datasets/COOLEY/'
process.env.HUBOT_GOOGLE_CHART_URL ||= 'http://chart.googleapis.com/chart?'

module.exports = (robot) ->

  robot.respond /startups/i, (msg) ->
    msg.reply "I can tell you a little about startups!"

  #
  # Startup Valuations
  # Startup financing is typically done in several rounds, as the startup company grows and its capital needs evolve. The first institutional round is 
  # usually called the "Series A round". Later rounds are called Series B, C, D, etc.
  # 
  # Command:
  #   user > hubot startup vals
  #
  robot.respond /startup (valuations|vals)/i, (msg) ->

    curDate = new Date()
    curDate.setYear(curDate.getFullYear()-3) # Get the date three years ago
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

            finalUrl = "#{imageUrl}#.png"
            gShort.shorten finalUrl, (err, url) ->
              msg.send(url); # http://goo.gl/fbsS
              msg.send rdata.description

          else 

            msg.send "The dataset was too confusing, so I gave up."

  #
  # The 7 Step Startup Investment Process for Venture Capitalists
  # It's not as easy as they make it out to be on Shark Tank. In the words of Meek Mill, "there are levels to this shit."
  # 
  # Command:
  #   user > hubot stp
  #
  robot.respond /startup investment process|stp/i, (msg) ->
      process_details = "The 7 Step Startup Investment Process for Venture Capitalists\n"
      process_details += "1. Identify the startup to invest in.\n"
      process_details += "2. Initial screening - Get to know more about the business and the entrepreneur.\n"
      process_details += "3. Second screening – This could involve workshops, a deeper dive, specific Q&A and in these an investor may bring in multiple subject matter experts that are trusted or that are leading other investments from within the firm.\n"
      process_details += "4. Light due dilligence\n"
      process_details += "5. The partner meeting - This is where the investment thesis is initially presented by the investor to the partners. This could be in person, socializing the deal, or by circulating a memo.\n"
      process_details += "6. Entrepreneur invited to present to partners - This is a good sign that the partners liked the investment thesis and are ready to invest.\n"
      process_details += "7. Terms and due dilligence - Signing the paperwork and covering terms.\n"
      msg.send process_details


  #
  # Investment Resources
  # This what the investors are reading and following.
  # 
  # Command:
  #   user > hubot investment resources
  #
  robot.respond /investment resources|ir/i, (msg) ->
      books_ar = [
        "Angel Investing: The Gust Guide to Making Money and Having Fun Investing in Startups by David S. Rose (http://amzn.to/1sJTcS8)"
        "Venture Deals: Be Smarter Than Your Lawyer and Venture Capitalist by Brad Feld (http://amzn.to/1bia6Qa)"
        "The Alliance Framework by Reid Hoffman, Ben Casnocha and Chris Yeh (http://www.theallianceframework.com)"
        "Early Exits: Exit Strategies for Entrepreneurs and Angel Investors (But Maybe Not Venture Capitalists) by Basil Peters (http://amzn.to/1wYvUxQ)"
        "The Definitive Guide to Raising Money from Angels by Bill Payne (Download @ http://bit.ly/1uqWS0e)"
      ]
      books_str = "-- Books --\n"
      for i in [0..books_ar.length-1] by 1
        books_str += (i+1) + ". " + books_ar[i] + "\n"

      blogs_ar = [
        "Venture Hacks (http://venturehacks.com)"
        "Adventures in Capitalism (http://adventuresincapitalism.com)"
      ]
      blogs_str = "-- Blogs -- \n"
      for i in [0..blogs_ar.length-1] by 1
        blogs_str += (i+1) + ". " + blogs_ar[i] + "\n"

      people_ar = [
        "Bill Payne"
        "John O. Huston"
        "David S. Rose"
        "Chris Yeh"
        "Howard Tullman"
        "George Deeb"
        "Charlie O'Donnell"
        "Jeffrey Carter"
        "Michael Gruber"
        "Gabriel Weinberg"
        "Glen Gottfried"
        "Ann Winblad"
        "Erin Griffith"
        "Troy Henikoff"
        "Dave Berkus"
        "Imran Ahmad"
        "Jerry Neumann"
        "Rob Go"
      ]
      people_str = "-- People -- \n"
      for i in [0..people_ar.length-1] by 1
        people_str += (i+1) + ". " + people_ar[i] + "\n"

      msg.send books_str + "\n" +  blogs_str + "\n" + people_str

