#
# Copyright (c) 2006-2025 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - https://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
class F5_bigip_cookie_disclosure < BeEF::Core::Command
  def post_execute
    return if @datastore['results'].nil?

    save({ 'BigIPCookie' => @datastore['results'] })
  end
end
