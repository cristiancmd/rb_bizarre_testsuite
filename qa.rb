require 'net/http'
require 'nokogiri'

def parse_error(body)
  return "" unless body.include?('<h1>')
  doc = Nokogiri::HTML(body)
  h1_content = doc.at_css('h1').text.strip
  return "#{h1_content}"
end

file_path = 'urls.txt'

if File.exist?(file_path)
  urls = File.readlines(file_path).map(&:strip).reject(&:empty?)
else
  puts "Error: The file '#{file_path}' does not exist."
  exit
end

url_data = {}
sucess_count = 0
error_count = 0

urls.uniq.each do |url|
  uri = URI(url)

  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    status = 'Success'
    sucess_count += 1
  else
    status = 'Error'
    error_message = "HTML: "
    error_message += "#{parse_error(response.body)}" if response.code.to_i >= 500
    error_count += 1
  end

  url_data[url] = { 'Status' => status, 'Error' => error_message, 'Code' => response.code }

rescue StandardError => e
  url_data[url] = { 'Status' => 'Error', 'Error' => e.message }
  error_count += 1
end

sorted_url_data = url_data.sort_by { |_, data| data['Status'] }


sorted_url_data.each do |url, data|
  puts "URL: #{url}"
  puts ""
  puts "Status: #{data['Status']}"
  puts "Error: #{data['Error']}" if data['Status'] == 'Error'
  puts "Code: #{data['Code']}" if data['Code']
  puts '---------------------------------'
end

puts "Total URLs: #{sorted_url_data.size}"
puts "Success: #{sucess_count}"
puts "Error: #{error_count}"
