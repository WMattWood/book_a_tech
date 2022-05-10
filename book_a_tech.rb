# BOOK A TECH
# this is a mockup of a booking system for connecting member techs with venues,
# events, and booking companies who need techs.

# many objects below will need to be manually created via a human.  To start with,
# this human will just be Justin.  As we onboard sw_clients, they can send us their
# own gig_client sheets which we can pre-populate into a webform for them.  This 
# would have to be a separate little utility (which should not interact with this 
# codebase) that could take a formatted .xml file to load in values.  Oooooooor
# again could be done manually.
# THE POINT HERE BEING: at first all gigs are punched in by hand by Justin, but
# over time it could be possible for gig_clients to be given accounts and they could
# have their own "client facing" interface for submitting requests, thus cutting 
# Justin (or any sw_client's admin person) out of the loop entirely... their function
# would be purely for pruning and maintenance of the DB and answering human phone calls.


class Calendar
  # interface with Google Calendar
  # https://developers.google.com/calendar/api/quickstart/ruby
  # each date should have the following properties/methods:
    # date (a string or 'date' object)
    # has_gigs? (boolean)
    # gigs_fulfilled? (boolean)
    # available_techs (an array)
  attr_accessor :bookings

  def initialize
    @bookings = [] # [ { 'date' => [ gig.id, gig.id ] }, 
                   #   { 'date' => [ gig.id, gig.id ] },
                   #   { 'date' => [ gig.id, gig.id ] },
                   #   { 'date' => [ gig.id, gig.id ] },
                   #   { 'date' => [ gig.id, gig.id ] },
                   # ]
  end

  def add_gig_to_calendar(given_date, gig)
    if bookings[given_date] # if an entry for the given date exists in @bookings array...
      bookings[given_date] << gig # ...add a new gig entry to the given date.
    else                          # otherwise...
      bookings[given_date] = [gig] # ...create a new entry with the date & gig provided.
    end
  end

  def cancel_gig(given_date, gig)
    bookings[given_date].delete(gig)
  end

  def gigs_fulfilled?(given_date)
    bookings[given_date].all? { |gig| gig.call_list_filled?}
  end

  def display_gigs(given_date)
    bookings[given_date].each { |gig| gig.to_s }
  end

  def tomorrow_call_list
    # send tomorrow's call list to all techs on the call list
  end

  def todays_call_list
    # send today's call list to the dispatch
  end
end

class Tech
  
  def initialize(name, email='bookings@justinsinbox.com', phone='justinsphonenumber', address, dept)
    @name = name # tech name
    @email = email # email
    @phone = phone # phone number - used to send booking requests and reminders
    @address = address # home/business address
    # @dept = dept # [audio, lx, vid, carp, head-audio, head-lx, head-vid, head-carp]
    @gigs = [] # array of gig objects for which tech has been confirmed
    @days_off = [] # array of dates where the tech is not available.
  end

  def not_available(start_date, end_date=start_date)
    dates = []
    # from start_date until end_date, push each day into an array call 'dates'
    dates.each do |day|
      days_off << day
    end
  end

  private

  attr_writer :days_off
end



class Gig # Collaborator objects include: Client, Venue, Date, CallList
  # Similar to notes on CallList below, this object may need to connect with
  # a webform of some kind.  Information pulled from the webform could include
  # ...well shit it could include all of the variables we use in the constructor
  # method below.  So the human on the other side of the form would be manually
  # entering in the client name, venue name, date, and call list.  

  def initialize(client, venue, date, call_time, call_list, notes=nil)  
    @client = client # pass in a client object
    @venue = venue # pass in a venue object
    @date = date # date of the event - maybe use Google Calendar date?  
    @call_list = call_list # a CallList instance object
    @call_time = call_time # should be a string... 
    @notes = notes # ie. "Call Time 6h00 @ Metro Joliette"
    # @@id = id ??? needs to count up as we make gigs?
  end

  def fill_position(position, tech)
    call_list[position] = tech
  end

  # EXAMPLE OF A CALL TO: (Gig)#fill_position
  # spectre_pdc_05032022.fill_position('lx001', 'Matthew Wood')
  # spectre_pdc_05032022.fill_position('lx002', 'Justin Tanguir')
  # spectre_pdc_05032022.fill_position('vid001', 'Ollis Seaworth')
  # spectre_pdc_05032022.fill_position('vid001', 'Ollis Seaworth')

  def cancel_position(position)
    call_list[position] = nil
  end

  def call_list_filled?
    call_list.all? {|position, filled| filled }
  end

  def add_notes(string)
    notes = string
  end

  def id_number
    # need to generate a unique id for each booking
    # should we have separate markers for montage/demontage?
  end

  def to_s
    "#{client.name}_#{venue.name}_#{id_number}"
  end

  def description
    "CREW CALL for #{self.date} @ #{self.venue} #{self.call_time}\nNOTES: #{self.notes}"
  end

  def display_call_list
    call_list.each do |position, _|
      puts position
    end
  end

  private
  
  attr_accessor :call_list 
  attr_write :notes
end

class Client # Collaborator object to Gig, BookingSystem

  def initialize(name, email='bookings@justinsinbox.com', phone='justinsphonenumber', address, responsable)
    @name = name # company name (ie. Spectra)
    @email = email # email address for sending billing information
    @phone = phone # formatted phone string, used for office purposes
    @address = address # billing address for company
    @responsable = responsable # string - the person who manages payments (Mariejo, Francis, Yves, etc)
  end
end

class Venue # Collaborator object to Gig
  
  def initialize(name, address, iatse=false, not_central=false)
    @name = name # Name of the venue... PDC, CentreBell, PlaceBell, etc.)
    @address = address # Address of the venue
    @iatse = iatse # Status of IATSE certification/requirement
    @not_central = not_central # Whether or not the venue is accessible by metro or requires car/uber
  end
end

class Date # Collaborator object to Gig
  # decide some portable format for date which can be passed throughout program
  # options...
    # Jan, Fev, Mar, Avr, Mai, Jun, Jul, Aug, Sep, Oct, Nov, Dec
    # Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec
    # Jan 22 2022 (MONDAY)

  def to_s
    "#{month} #{day} #{year} (#{day_of_the_week})"
  end
end

class CallList # Collaborator object to Gig
  # this object may pull data from a webform...
    # the webform may take the following shape...
      # How many lighting techs do you need?
      # How many audio techs do you need?
      # How many carp techs do you need?
      # How many video techs do you need?
      # How many head_lighting techs do you need?
      # How many head_audio techs do you need?
      # How many head_carp techs do you need?
      # How many head_video techs do you need?
      # How many show_audio techs do you need
      # How many show_lighting techs do you need
      # How many show_video techs do you need
      # How many show_followspot techs do you need
      # How many show_stagehand techs do you need

  # a call list will be a hash object
  # { 'LX 001' => nil, 'LX 002' => nil, 'Audio 001' => nil}
  attr_reader :positions

  def initialize(gig_request_xml)
    @positions = parse(gig_request_xml)
  end

  private

  attr_reader :positions

  def parse(xml)
    # output = {}
    # file.each_line do |line1, line2|
    #   output[line1] = line2
    # end
    # output
    # # this would be a method that would parse xml file into an appropriate hash
  end

  def to_s
    positions
  end
end


class BookingSystem # Orchestration system

  def submit_gig_request
    # receive a client request submission
    # details for a gig must be manually entered into the system
    # include some checks for formatting and good data

    # may need a constructor to generate number of techs... who decides that? 

    # ...potentially link to a google form?
    # ...
  end

  def create_gig(gig_request_xml)
    client = get_client(gig_request_xml)
    venue = get_venue(gig_request_xml)
    date = get_date(gig_request_xml) 
    call_time = get_call_time(gig_request_xml)
    call_list = get_call_list(gig_request_xml)
    Gig.new(client, venue, date, call_time, call_list)
  end

  def get_client(gig_request_xml)
    # returns client as a Client.new object
    # OR ACCESSES DATABASE TO PULL EXISTING OBJECT?
  end

  def get_venue(gig_request_xml)
    # returns venue as a Venue.new object
    # OR ACCESSES DATABASE TO PULL EXISTING OBJECT?
  end

  def get_date(gig_request_xml)
    # returns date as a Date.new object
  end

  def get_call_list(gig_request_xml)
    # returns call_list as a CallList.new object
    CallList.new(gig_request_xml)
  end

  def get_call_time(gig_request_xml)
    # returns call_time as a string
  end

  def add_gig_to_calendar
    # upon successful client request submission...
    # ...add the gig to the appropriate date on the calendar.
  end

  def send_gig_request
    # upon successful client request submission (and adding gig to calendar...)
    # ...send out a mass text to all tech who are available on the gig.date
  end

  def confirm_tech_booking
    # upon receiving acceptance text from Tech, send out a confirmation text 
    # ...confirming the booking and providing Tech with details.
  end

  def add_to_call_list # (optional method... might be extraneous)
    # upon confirmation, add the techs phone number and email to a call list for reminders/hassling
  end

  def send_reminders
    # text all the techs booked on a given day 24hrs in advance
  end

  def send_receipt
    # text all the techs booked on a given day with the billing info:
      # client.name
      # client.email
      # client.phone
      # client.responsable
      # gig.to_s (prints gig_id)
  end
end

module DatabaseManagement
end

# Billing instructions: 
# Send an invoice with your name, phone number, email, and billing/home address
# On the invoice, bill to as follows:
# "CLIENT NAME"
# c/o "Responsable"
# "Client Billing Address"
# "Client Phone"
# Send it to the client email
# Address the email to the responsable (ie. 'Dear Ms. Jolene', or 'Hi Corey,')
