#
# Copyright (c) 2006-2025 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - https://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
class Detect_vlc < BeEF::Core::Command
  def post_execute
    content = {}
    content['vlc'] = @datastore['vlc']
    save content
    BeEF::Core::Models::BrowserDetails.set(@datastore['beefhook'], 'browser.capabilities.vlc', Regexp.last_match(1)) if @datastore['results'] =~ /^vlc=(Yes|No)/
  end
end
