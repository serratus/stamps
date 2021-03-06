require 'hashie'
require 'savon'
require File.expand_path('../response', __FILE__)

module Stamps

  # Defines HTTP request methods
  module Request

    # Perform an HTTP request
    def request(web_method, params, raw=false)
      client = Savon::Client.new do |wsdl, http|
        wsdl.endpoint = self.endpoint
        wsdl.namespace = self.namespace
      end

      response = client.request :tns, web_method do
        http.headers = { "SoapAction" => formatted_soap_action(web_method) }
        soap.namespace = 'tns'
        soap.element_form_default = :qualified
        soap.env_namespace = 'soap'
        soap.namespaces["xmlns:tns"] = self.namespace
        soap.body = params.to_hash
      end
      response = Stamps::Response.new(response).to_hash
	  response_hash = response.values.detect {|v|  v.has_key?(:authenticator) if v.is_a?(Hash) }
	  @authenticator = response_hash[:authenticator] if response_hash
	  response
    end

    # Get the Authenticator token. By using an Authenticator, the integration
    # can be sure that the conversation between the integration and the SWS
    # server is kept in sync and no messages have been lost.
    #
    def authenticator_token
      @authenticator ||= self.get_authenticator_token
    end
	
	# manually set the authenticator token
	def authenticator_token=(value)
	  @authenticator = value
	end

    # Make Authentication request for the user
    #
    def get_authenticator_token
      self.request('AuthenticateUser',
        Stamps::Mapping::AuthenticateUser.new(
          :credentials => {
            :integration_id => self.integration_id,
            :username       => self.username,
            :password       => self.password
        })
      )[:authenticate_user_response][:authenticator]
    end

    # Concatenates namespace and web method in a way the API can understand
    def formatted_soap_action(web_method)
      [self.namespace, web_method.to_s].compact.join('/')
    end

  end
end
