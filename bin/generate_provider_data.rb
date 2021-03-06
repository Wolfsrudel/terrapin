#!/usr/bin/env ruby
require 'nokogiri'
require 'json'
require 'open-uri'

page = Nokogiri::HTML(open("https://terraform.io/docs/providers"))
provider = []

page.css(".nav a").each do |x|
  if x['href'] =~ /docs\/providers\/.*\/index.html/ then
    provider.push(x['href'])
  end
end

if not Dir.exist? "provider_json/#{ARGV[0]}"
  Dir.mkdir "provider_json/#{ARGV[0]}"
end

provider.each do |i|
    page = Nokogiri::HTML(open("https://terraform.io#{i}"))
    provider_name = i.split('/')[-2]
    links = []
    provider_arguments = []

    puts "Starting Provider of #{provider_name}"

    page.css("#argument-reference ~ ul:first-of-type > li").each do |e|
      name = e.css('a').text()
      info = e.text()
      if not name.nil? then
        name = (not name.include? "-") ? name : name.split("-")[0]
        provider_arguments.push({ 'word' => name, "info" => info})
      end
    end

    page.css(".docs-sidenav a").each do |x|

      if not x['href'] == '#' then
        if not x['href'] == "/docs/providers/#{provider_name}/index.html" then
          if not x['href'] == '/docs/providers/index.html' then
            links.push([x['href'], x.text()])
          end
        end
      end
    end

    result = {}

    result["provider_arguments"] = provider_arguments
    result["resources"] = {}
    result["datas"] = {}
    result["unknowns"] = {}

    links.each do |x|
      page = Nokogiri::HTML(open("http://terraform.io#{x[0]}"))

      arguments = []
      attributes = []
      location = ""

      if x[0].match? /\/docs\/providers\/[^\/]*\/r\/.*/
        location = "resources"
      elsif x[0].match? /\/docs\/providers\/[^\/]*\/d\/.*/
        location = "datas"
      else
        location = "unknowns"
      end

      page.css("#argument-reference ~ ul:first-of-type > li").each do |i|
        begin
          begin
            name = i.css("a[name]")[0]['name']
          rescue
            name = i.css("a[href]")[0]['href']
          end
          if i.css("p").empty?
            info = i.text()
          else
            info = i.css("p")[0].text()
          end
          if not name.nil? then
            name = (not name.include? "-") ? name : name.split("-")[0]
            arguments.push({ 'word' => name, "info" => info})
          end
        rescue
        end
      end

      page.css("#attributes-reference ~ ul:first-of-type li").each do |i|
        begin
          begin
            name = i.css("a[name]")[0]['name']
          rescue
            name = i.css("a[href]")[0]['href']
          end
          info = i.text()
          if not name.nil? then
            name = (not name.include? "-") ? name : name.split("-")[0]
            attributes.push({ 'word' => name, "info" => info})
          end
        rescue
        end
      end

      page.css("#attribute-reference ~ ul:first-of-type li").each do |i|
        begin
          begin
            name = i.css("a[name]")[0]['name']
          rescue
            name = i.css("a[href]")[0]['href']
          end
          info = i.text()
          if not name.nil? then
            name = (not name.include? "-") ? name : name.split("-")[0]
            attributes.push({ 'word' => name, "info" => info})
          end
        rescue
        end
      end

      name = x[1]
      if name.split('_')[0] == provider_name
        name = name.split('_')[1..-1].join('_')
      end
      result[location][name] = { "provider" => provider_name, "arguments" => arguments, "attributes" => attributes }
      puts "Finish #{name} of #{provider_name}"
    end

    if provider_name == "do" then
      provider_name = "digitalocean"
    end

    File.open("provider_json/#{ARGV[0]}/#{provider_name}.json", 'w') { |file| file.write(JSON.generate(result)) }
end