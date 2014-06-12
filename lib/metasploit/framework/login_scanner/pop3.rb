require 'metasploit/framework/login_scanner/base'
require 'metasploit/framework/login_scanner/rex_socket'
require 'metasploit/framework/tcp/client'

module Metasploit
  module Framework
    module LoginScanner

      # This is the LoginScanner class for dealing with POP3.
      # It is responsible for taking a single target, and a list of credentials
      # and attempting them. It then saves the results.
      class POP3
        include Metasploit::Framework::LoginScanner::Base
        include Metasploit::Framework::LoginScanner::RexSocket
        include Metasploit::Framework::Tcp::Client

        # This method attempts a single login with a single credential against the target
        # @param credential [Credential] The credential object to attempt to login with
        # @return [Metasploit::Framework::LoginScanner::Result] The LoginScanner Result object
        def attempt_login(credential)
          result_options = {
            credential: credential,
            status: :failed
          }

          disconnect if self.sock

          begin
            connect
            select([sock],nil,nil,0.4)
            # sleep(0.4)

            # Check to see if we recieved an OK?
            result_options[:proof] = sock.get_once
            if result_options[:proof][/^\+OK.*/]
              # If we received an OK we should send the USER
              sock.put("USER #{credential.public}\r\n")
              result_options[:proof] = sock.get_once
              if result_options[:proof][/^\+OK.*/]
                # If we got an OK after the username we can send the PASS
                sock.put("PASS #{credential.private}\r\n")
                result_options[:proof] = sock.get_once
                if result_options[:proof][/^\+OK.*/]
                  # if the pass gives an OK, were good to go
                  result_options[:status] = :success
                end
              end
            end
          rescue Rex::ConnectionError, EOFError, Timeout::Error, Errno::EPIPE => e
            result_options.merge!(
              proof: e.message,
              status: :connection_error
            )
          end

          disconnect if self.sock

          Result.new(result_options)
        end

        private

        # (see Base#set_sane_defaults)
        def set_sane_defaults
          self.max_send_size ||= 0
          self.send_delay ||= 0
          self.port ||= 110
        end

     end

    end
  end
end
