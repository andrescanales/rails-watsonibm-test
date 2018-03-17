class WelcomeController < ApplicationController
	require 'rubygems'
	require 'excon'
	require 'json'

  def index		

  end

  def results
  	if params[:account] && !params[:account].blank?
  		# 1. First we obtain 50 tweets from the account
  		begin
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

				# 4. Next, we configurate the arrays for chart js data:
		 		personalities = []
		 		percentages = []
		 		colours = []
		 		
		 		# Variables used to determinate the winner personality
		 		@dominant_personality = ''
		 		personality_percentage = 0

				@json_response = JSON.parse(response.body)
				@json_response['personality'].each do |d|
					personalities << d['name']
					percentages << d['percentile'] * 100
					# Random colors for chart
					colour = "#"+"%06x" % (rand * 0xffffff)
					colours << colour.to_s
					if @dominant_personality == ''
						@dominant_personality = d['name']
						personality_percentage = (d['percentile'] * 100)
					else
						if personality_percentage < (d['percentile'] * 100)
							@dominant_personality = d['name']
							personality_percentage = (d['percentile'] * 100)
						end
					end
				end

				if @dominant_personality == 'Openness'
		  		@music = "classical, blues, jazz, and folk"
		  	elsif @dominant_personality == 'Conscientiousness'
		  		@music = "classical, blues, jazz, gospel"
		  	elsif @dominant_personality == 'Extraversion'
		  		@music = "rap, hip hop, soul, electronic, and dance"
		  	elsif @dominant_personality == 'Agreeableness'
		  		@music = "soul, pop, and hip hop"
		  	elsif @dominant_personality == 'Emotional range'
		  		@music = "Country, pop"
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

				# 5. Finally we save the data in database:
				@user = User.new(username: params[:account], primary_trait: @dominant_personality, music_recomendation: @music)
				@user.save

				respond_to do |f|
			    f.html { redirect_to index_url }
			    f.js
			  end
			
			rescue Twitter::Error::NotFound => e
				render js: "alert('Account does not exists!'); $('.loader').hide();"
			end

		else
			render js: "alert('You can not leave twitter account empty!'); $('.loader').hide();"
	  end
  end

end
