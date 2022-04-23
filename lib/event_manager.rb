require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'




def clean_zipcode(code)
    code.to_s.rjust(5, '0')[0..4]
=begin
    if code.nil?
        code = '00000'

    elsif code.length < 5
        code = code.rjust(5, '0')

    elsif code.length > 5
        code = code[0..4]      
    end
    code
=end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
        #legislators = legislators.officials
        #leg_name = legislators.map(&:name).join(", ")

    rescue 
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
  
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
end

def clean_phone_number(p_number)
    p_number = p_number.scan(/\d/).join('')

    if  p_number.length < 10 || p_number.length > 11
        p_number = "invalid"

    elsif p_number.length == 11
        if p_number[0] == 1
            p_number = p_number.slice(0)
        else
            p_number = "invalid"
        end
    end

    p_number.insert(3, '-') unless p_number == "invalid"
    p_number.insert(7, '-') unless p_number == "invalid"

    p_number
end

def time(hrs)
    hrs = hrs.reduce(Hash.new(0)) do |hour, visits|
        hour[visits] += 1
        hour
    end
    hrs
end

def day(wk)
    case wk
        when 0 
            wk = "sunday"
        when 1 
            wk = "monday"
        when 2 
            wk = "tuesday"
        when 3
            wk = "wednesday"
        when 4
            wk = "thursday"
        when 5
            wk = "friday"
        when 6
            wk = "saturday"
        else "invalid date"
    end
    wk
end

def wkdays(days)
    days = days.reduce(Hash.new(0)) do |dy, visits|
        dy[visits] += 1
        dy
    end
    days
end

#puts "Event Manager Initialized!"
file = '/home/gche/repos/event_manager/event_attendees.csv'
template_letter = File.read('/home/gche/repos/event_manager/form_letter.erb')
erb_template = ERB.new template_letter

if File.exist? file
    contents = CSV.open(file, headers: true, header_converters: :symbol)
    hours = []
    weekdays = []

    contents.each do |row| 
        id = row[0]
        first_name = row[:first_name]
        zipcode = clean_zipcode(row[:zipcode])
        phone_number = clean_phone_number(row[:homephone])
        puts phone_number
       
        hour = DateTime.strptime(row[:regdate], '%m/%d/%Y %H:%M').hour
        hours << hour

        week = DateTime.strptime(row[:regdate], '%m/%d/%Y %H:%M').wday
        weekdays << day(week)

        legislator_name = legislators_by_zipcode(zipcode)
        
        form_letter = erb_template.result(binding)

        save_thank_you_letter(id,form_letter)
        
    end
    puts time_target = time(hours)
    puts weekday_target = wkdays(weekdays)
end

