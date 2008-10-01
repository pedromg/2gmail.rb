#! /usr/bin/ruby

##
# == rememeber: 
#   * insert your login and password at Line 100, and save this file.
#   * of couse, be very carefull if you send this to a friend... REMOVE your credentials first!
*   * if you are using Google Hosted for your Domain (Google Apps), your_login is something like: me@mydomain.com
#   * example: go = GoGmail.new($*[0], 'imap.gmail.com', 993, $*[1], 'tree@forest.org', 'littlebird', $*[2])
#
# == usage:
#   $ chmod u+x 2gmail.rb
#   $ ./2gmail.rb MBOX_FILE GMAIL_FOLDER [STARTING_MESSAGE]
#
# ==  examples:
#     $ ./2gmail.rb Inbox tempInbox 250
#     $ ruby 2gmail.rb Inbox tempInbox 250
#     $ /path/to/ruby/ruby 2gmail.rb Inbox tempInbox 250
#
# == notice:
#   * v0.9.1
#   * who: pedro.mota@gmail.com 
#   * when: 03-dec-2007
#   * what: this is free software. use. refactor. share.
#   * the author will not be responsible for any bumps during the journey! This was done in some minutes!
#

require 'mailread'
require 'net/imap'
require 'time'
require 'logger'

class GoGmail

  def initialize(mboxfile, server, port, folder, user, pass, start)
    # open the mbox file
    @mbox = File.open(mboxfile)
    # open the gmail imap account
    @imap = Net::IMAP.new(server, port, true, nil, false)
    @imap.login(user, pass)
    @folder = folder
    # Verify gmail folder
    fverify
    # starting message
    start == nil ? @start = 0 : @start = start.to_i
    # log
    @log = Logger.new('2Gmail.log')
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:$S"
  end

  def fverify
    begin
      @imap.select(@folder)
    rescue 
      @imap.create(@folder)
      # todo: code the possibility of a Net::IMAP::NoResponseError
    end
  end

  def wrap_msg
    fmt_msg = ""
    # headers
    fmt_msg = @msg.header.collect { |h| "#{h[0]}: #{h[1].gsub(/\n/, "")}\r\n" }.to_s
    # and body (body separated by \r\n\r\n)
    fmt_msg += "\r\n"
    fmt_msg += "#{@msg.body.to_s.gsub(/\n/, "\r\n")}" 
  end

  def bulk_upload
    # append all the mbox messages
    @log.info("=================")
    @log.info("Bulk Upload Start")
    count = 0
    errors = 0
    # position in the correct index
    while (count < @start) and (!@mbox.eof?) : count += 1 end 
    # start
    while !@mbox.eof?
      begin
        @msg = Mail.new(@mbox)
        imsg = wrap_msg
        @log.debug("Executing msg. [#{count}] : #{@msg.header["Subject"]} : #{@msg.header["Date"]}")
        @imap.append(@folder, imsg, nil, Time.parse(@msg.header["Date"]))
        count += 1
        p "Successfully sent message nr.: #{count}"
      rescue => e
        @log.warn("Error in msg. [#{count}] : #{@msg.header["Subject"]} : #{@msg.header["Date"]}")
        errors += 1
        p "Error in msg [#{count}]: #{e}"
        next
      end
    end
    @log.info("Bulk Upload Finished: #{count} messages : #{errors} errors")
  end

  def bye
    @imap.disconnect
  end
end


login = 'YOUR_LOGIN'
passwd = 'YOUR_PASSWORD'

go = GoGmail.new($*[0], 'imap.gmail.com', 993, $*[1], login, passwd, $*[2])
go.bulk_upload
go.bye


