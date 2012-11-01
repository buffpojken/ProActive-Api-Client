require 'json'
require 'restclient'
require 'digest/sha1'

# Edit these if you want to testout the API 
def make
	method	  	= :post # or :put
	data 				= {:data => {:sickness_type => {:name => "Sickness A", :code => "sickness_a", :group => "1234"}}.to_json}
	secret_key 	= # Secret Key Here
	path 				= "http://proactive.dev.monkeydancers.com/api/v1/sickness_types"

	comms 			= ApiCommunicator.new(method, path, data, secret_key, {:format => "application/json"})
	comms.success do |response|
		puts "Success: #{response.inspect}"
	end
	comms.run
end




# Private, never you mind! This just wraps all the signature-management! .daniel
class ApiCommunicator

	def initialize(method, path, data, secret_key, opts = {:format => "application/xml"})
		@method 	= method
		@data 		= data
		@secret 	= secret_key
		@path 		= path
		@opts			= opts
	end

	def run
		time = Time.now.to_i
		sig = generate_sig(time)
		begin
			if @method.eql?(:post) || @method.eql?(:put)
				response = RestClient.send(@method, @path, @data, {'PA-SIG' => sig, 'PA-TP' => time, 'Accept' => @opts[:format]})
			else
				response = RestClient.send(@method, @path, {'PA-SIG' => sig, 'PA-TP' => time, 'Accept' => @opts[:format]})
			end
		rescue Exception => e
			if @err
				@err.call
			else
				raise e
			end
		else
			if @succ
				@succ.call(response)
			else
				return response
			end
		end
	end

	def signature
		time = Time.now.to_i
		return time, generate_sig(time)
	end

	def success(&blk)
		@succ = blk
	end

	def error(&blk)
		@err = blk
	end

	private

	def generate_sig(time)
		return Digest::SHA1.hexdigest([generate_sig_string(@data), time.to_i, @secret].join("."))
	end

	def generate_sig_string(data)
		sig_string = ""
		@data.keys.sort.each{|key| sig_string << key.to_s; sig_string << "."; sig_string << @data[key]}
		sig_string
	end
end

make if __FILE__ == $0