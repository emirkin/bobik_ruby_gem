require 'json'
require 'httparty'

module Bobik
  # Author::    Eugene Mirkin
  # This is the main class for interacting with Bobik platform.
  class Client
    include HTTParty
    base_uri 'https://usebobik.com/api/v1'

    # Notable parameters:
    # * :auth_token - [required] authentication token
    # * :timeout_ms - [optional] when to stop waiting for the job to finish
    # * :logger - [optional] any logger that conforms to the Log4r interface
    # Be aware that Timeout::Error may be thrown.
    def initialize(opts)
      @auth_token = opts[:auth_token] || raise(Error.new("'auth_token' was not provided"))
      @timeout_ms = opts[:timeout_ms] || 60000
      @log = opts[:logger] || (defined?(Rails.logger) && Rails.logger)
    end
    
    # Submit a scraping request.
    # The callback block will be invoked when results arrive.
    # If asynchronous mode is used, the method returns right away.
    # Otherwise, it blocks until results arrive.
    def scrape(request, block_until_done, &block)
      request = Marshal.load(Marshal.dump(request))
      request[:auth_token] = @auth_token

      job_response = self.class.post('/jobs.json', :body => request)
      raise Error.new(job_response['errors'].join("\n")) if job_response['errors']
      job_id = job_response['job']

      Thread.abort_on_exception = true
      t = Thread.new do
        wait_until_finished(job_id, &block)
      end
      t.join if block_until_done
      true
    end
    
  private
    
    # Blocks until the job is finished or timeout is reached.
    # When done, yields results to the optional block.
    # Exceptions thrown: Timeout::Error, Errno::ECONNRESET, Errno::ECONNREFUSED
    def wait_until_finished(job_id, &block)
      log("Waiting for job #{job_id} to finish")
      results = nil
      errors = nil
      Timeout::timeout(@timeout_ms.to_f/1000) do
        while true
          job_response = get_job_data(job_id, false)
          progress = job_response['progress']
          log("Job #{job_id} progress: #{progress*100}%")
          if progress == 1
            job_response = get_job_data(job_id, true)
            results = job_response['results']
            errors = job_response['errors']
            break
          end
          sleep(job_response['estimated_time_left_ms'].to_f/1000)
        end
      end
      block.call(results, errors)
    end
    
    # A single call to get a given job's status with or without results
    def get_job_data(job_id, with_results)
      job_response = self.class.get('/jobs.json', :body => {
        auth_token: @auth_token,
        no_results: !with_results,
        job:        job_id
      })
    end


    def log(msg)
      return unless @log
      @log.debug(msg)
    end
  end
end
