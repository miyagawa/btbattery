#!/usr/bin/env ruby
require 'plist'
require 'json'

def visit(thing, want, &block)
  case thing
  when Hash
    thing.keys.each do |key|
      if want.include?(key)
        yield key, thing[key]
      else
        visit thing[key], want, &block
      end
    end
  when Array
    thing.each do |value|
      visit value, want, &block
    end
  end
end

def json_path
  ENV['BATTERY_JSON_PATH'] || "#{ENV['HOME']}/Dropbox/Public/btbattery.json"
end

def load_data
  if File.exists?(json_path)
    JSON.load(File.read(json_path))
  else
    {}
  end
end

def save_data(batteries)
  File.write(json_path, JSON.dump(load_data.merge(batteries)))
end

def get_batteries
  batteries = {}

  plist = Plist::parse_xml(`ioreg -k BatteryPercent -a`)

  percent = nil
  visit plist, ["BatteryPercent", "Product"] do |key, value|
    case key
    when "BatteryPercent"
      percent = value if value.is_a?(Integer)
    when "Product"
      batteries[value] = percent
    end
  end

  batteries
end

def run
  save_data(get_batteries.merge("date" => Time.now))
end

run
