module Stamps

  # = Stamps::Response
  #
  # Represents the response and contains the HTTP response.
  #
  class Response

    # Expects an <tt>Savon::SOAP::Response</tt> and handles errors.
    def initialize(response)
      self.errors = []
      self.valid = true
      self.savon  = response
      self.http   = response.http
      self.hash   = self.savon.to_hash
      raise_errors
    end

    attr_accessor :savon, :http, :errors, :valid, :hash, :code

    # Returns the SOAP response body as a Hash.
    def to_hash
      self.hash.merge!(:errors => self.errors)
      self.hash.merge!(:valid? => self.valid)
      self.hash
      Stamps.format.to_s.downcase == 'hashie' ? Hashie::Mash.new(@hash) : self.hash
    end

    # Um, there's gotta be a better way
    def valid?
      self.valid
    end

    # Process any errors we get back from the service.
    # Wrap any internal errors (from Soap Faults) into an array
    # so that clients can process the error messages as they wish
    #
    def raise_errors
      message =  'Error'
      if savon.soap_fault.present?
        self.format_soap_faults
      end

      case http.code.to_i
      when 200
        return
      when 400
        raise BadRequest.new({errors: self.errors, http_code: http.code}), "(#{http.code}): BadRequest"
      when 401
        raise Unauthorized.new({errors: self.errors, http_code: http.code}), "(#{http.code}): Unauthorized"
      when 403
        raise Forbidden.new({errors: self.errors, http_code: http.code}), "(#{http.code}): Forbidden"
      when 404
        raise NotFound.new({errors: self.errors, http_code: http.code}), "(#{http.code}): NotFound"
      when 406
        raise NotAcceptable.new({errors: self.errors, http_code: http.code}), "(#{http.code}): NotAcceptable"
      when 500
        raise InternalServerError.new({errors: self.errors, http_code: http.code}), "(#{http.code}): InternalServerError"
      when 502..503
        raise ServiceUnavailable.new({errors: self.errors, http_code: http.code}), "(#{http.code}): ServiceUnavailable"
      end
    end

    # Include any errors in the response
    #
    def format_soap_faults
      fault = self.hash.delete(:fault)
      self.errors << fault[:faultstring]
      self.valid = false
    end

  end
end
