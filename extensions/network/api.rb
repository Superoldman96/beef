#
# Copyright (c) 2006-2025 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - https://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
  module Extension
    module Network
      module RegisterHttpHandler
        BeEF::API::Registrar.instance.register(BeEF::Extension::Network::RegisterHttpHandler, BeEF::API::Server, 'mount_handler')

        # Mounts the handler for processing network host info.
        #
        # @param beef_server [BeEF::Core::Server] HTTP server instance
        def self.mount_handler(beef_server)
          beef_server.mount('/api/network', BeEF::Extension::Network::NetworkRest.new)
        end
      end
    end
  end
end
