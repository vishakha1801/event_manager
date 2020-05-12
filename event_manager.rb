require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  phone = phone.to_s.scan(/\d+/).join
  if phone.length != 10
    if phone.length == 11 && phone[0] = '1'
      phone = phone[1..-1]
    else
      phone = '0000000000'
    end
  end
  phone[0..2] + '-' + phone[3..5] + '-' + phone[6..9]
end

def peak_hours(all_hours)
  puts 'PEAK HOURS:'
  puts '-----------'
  total = all_hours.values.inject(0) { |sum, i| sum + i }
  peak_hours = all_hours.sort_by { |k, v| v }.reverse.first 3
  peak_hours. each do |hour, count|
    puts "hour: #{hour} count: #{count} (#{(count.to_f / total * 100).round(1)}%)"
  end
  puts "\n"
end

# prints list of days with # of registrants, REFACTOR AT SOME POINT
def peak_days(days_of_week)
  puts 'PEAK DAYS'
  puts '---------'
  total = days_of_week.values.inject(0) { |sum, i| sum + i }
  sorted_days = days_of_week.sort_by { |k, v| v }.reverse
  sorted_days.each do |hour, count|
    puts "#{hour}:".rjust(10, ' ') + " #{count.to_s.rjust(4, ' ')} (#{(count.to_f / total * 100).round(1)}%)"
  end
  puts "\n"
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
#contents = CSV.open 'full_event_attendees.csv', headers: true, header_converters: :symbol, encoding: "ISO8859-1"

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter


all_hours = Hash.new(0) # hash to track peak # of registrants per hour
days_of_week = Hash.new(0) # has to track registrants by day

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
  phone = clean_phone(row[:homephone])
  reg_date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')

  # counters to keep track of registrants by hour and day
  all_hours[reg_date.hour] += 1
  days_of_week[reg_date.strftime('%A')] += 1

end


puts "\n"
peak_hours(all_hours)
peak_days(days_of_week)