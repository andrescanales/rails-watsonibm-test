class WelcomeController < ApplicationController
	require 'rubygems'
	require 'excon'
	require 'json'

  def index		
		# tweets = MyTwitter.user_timeline('pontifex', count: 50)
		# puts tweets.inspect
		# puts "-------------------------------------------------"
		# # tweets2 = MyTwitter.user_timeline("cnn", count: 4)
		# # puts tweets2.inspect

  end

  def results
  	if params[:account]
  		# 1. First we obtain 50 tweets from the account
  		tweets = MyTwitter.user_timeline(params[:account], count: 50)

  		tweets_json = []

  		# 2. Next we create a simple file with the IBM api format 
		  tweets.each do |t|
		    data_json = {
		      "content" => t.text,
		      "contenttype": "text/plain",
		      "language": "en"
		    } 
		    tweets_json << data_json
		  end

		  File.open("public/tweets.json","w") do |f|
		  	f.write("{\"contentItems\":")
		    f.write(tweets_json.to_json)
		    f.write("}")
		  end

		  # 3. We need to use the Chunked Requests feature of excon http client
		  file = File.open('public/tweets.json')

			chunker = lambda do
			  file.read(Excon.defaults[:chunk_size]).to_s
			end

			# 3.1. Making the request to the api
			response = Excon.post(
				'https://gateway.watsonplatform.net/personality-insights/api/v3/profile?version=2017-10-13&consumption_preferences=true&raw_scores=true',
				:user => Rails.application.secrets.ibm_user, :password => Rails.application.secrets.ibm_password,
				:request_block => chunker,
				:headers => { "Content-Type" => "application/json" }
			)

			# 4. Finally we configurate the arrays for chart js data:
	 		personalities = []
	 		percentages = []
	 		colours = []

			json_response = JSON.parse(response.body)
			json_response['personality'].each do |d|
				personalities << d['name']
				percentages << d['percentile'] * 100
				# Random colors for chart
				colour = "#"+"%06x" % (rand * 0xffffff)
				colours << colour.to_s
			end

			@data = {
			  labels: personalities,
			  datasets: [
			    {
			        label: "My First dataset",
			        background_color: colours,
			        data: percentages
			    }
			  ]
			}

			# @data = {
			#   labels: ["January", "February", "March", "April", "May", "June", "July"],
			#   datasets: [
			#     {
			#         label: "My First dataset",
			#         background_color: "rgba(220,220,220,0.2)",
			#         border_color: "rgba(220,220,220,1)",
			#         data: [65, 59, 80, 81, 56, 55, 40]
			#     },
			#     {
			#         label: "My Second dataset",
			#         background_color: "rgba(151,187,205,0.2)",
			#         border_color: "rgba(151,187,205,1)",
			#         data: [28, 48, 40, 19, 86, 27, 90]
			#     }
			#   ]
			# }
			respond_to do |f|
		    f.html { redirect_to index_url }
		    f.js
		  end

  	else
  	end
  end

end
