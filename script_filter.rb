#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'

class ScriptFilter
  # Read JSON array from the environment
  def self.load_services
    services_json = ENV['SERVICES_JSON'] || '[]'
    services = begin
      JSON.parse(services_json, symbolize_names: true)
    rescue JSON::ParserError
      []
    end
    
    # Return default services if empty or invalid
    services.empty? ? default_services : services
  end

  def self.default_services
    [
      { name: "Copilot",    code: "co",  urlTemplate: "https://github.com/copilot?prompt=${prompt}" },
      { name: "ChatGPT",    code: "gpt", urlTemplate: "https://chatgpt.com/?prompt=${prompt}" },
      { name: "Claude",     code: "cl",  urlTemplate: "https://claude.ai/new?q=${prompt}" },
      { name: "Perplexity", code: "px",  urlTemplate: "https://www.perplexity.ai/search/new?q=${prompt}" },
      { name: "Mistral",    code: "ms",  urlTemplate: "https://chat.mistral.ai/chat?q=${prompt}" }
    ]
  end

  def initialize(services = nil)
    @services = services || self.class.load_services
    @services = self.class.default_services if @services.empty?
  end

  def build_items_for_empty_input
    @services.map do |svc|
      {
        "title"        => "#{svc[:name]} (#{svc[:code]})",
        "subtitle"     => "Press Enter to select #{svc[:name]}, then type your prompt",
        "valid"        => false,
        "autocomplete" => "#{svc[:code]} "
      }
    end
  end

  def build_unknown_service_item
    {
      "title"    => "Unknown Service",
      "subtitle" => "Valid: #{ @services.map { |s| s[:code] }.join(', ') }",
      "valid"    => false
    }
  end

  def build_need_prompt_item(svc)
    {
      "title" => "Type your prompt for #{svc[:name]} (#{svc[:code]})",
      "subtitle" => "e.g. 'ask #{svc[:code]} how do I X?'",
      "valid" => false
    }
  end

  def build_final_item(svc, prompt)
    # Use URI.encode_www_form_component but replace + with %20
    encoded_prompt = URI.encode_www_form_component(prompt).gsub('+', '%20')
    url = svc[:urlTemplate].gsub('${prompt}', encoded_prompt)

    {
      "title"    => "Send to #{svc[:name]}",
      "subtitle" => prompt,
      "arg"      => url,
      "valid"    => true
    }
  end

  def process_input(input)
    return { "items" => build_items_for_empty_input } if input.empty?

    service_code, *rest = input.split(' ')
    prompt = rest.join(' ')

    svc = @services.find { |s| s[:code] == service_code }

    return { "items" => [build_unknown_service_item] } unless svc
    return { "items" => [build_need_prompt_item(svc)] } if prompt.empty?

    { "items" => [build_final_item(svc, prompt)] }
  end
end

# Only run the main script if this file is being executed directly
if __FILE__ == $PROGRAM_NAME
  filter = ScriptFilter.new
  input = ARGV.join(' ').strip
  puts filter.process_input(input).to_json
end
