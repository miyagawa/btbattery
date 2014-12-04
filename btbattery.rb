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

  %w[BNBTrackpadDevice AppleBluetoothHIDKeyboard].each do |klass|
    plist = Plist::parse_xml(`ioreg -c #{klass} -a`)
    props = {}
    visit plist, ["BatteryPercent", "Product"] do |key, value|
      props[key] ||= value
    end
    batteries[props["Product"]] = props["BatteryPercent"]
  end

  batteries
end

def run
  save_data(get_batteries.merge(date: Time.now))
end

run
