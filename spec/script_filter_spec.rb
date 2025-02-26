# frozen_string_literal: true

require 'rspec'
require 'open3'
require 'json'
require_relative '../script_filter'

RSpec.describe ScriptFilter do
  let(:script_path) { File.expand_path('../script_filter.rb', __dir__) }
  let(:default_services) { ScriptFilter.default_services }
  let(:filter) { ScriptFilter.new }

  before do
    # Reset SERVICES constant before each test
    if Object.const_defined?(:SERVICES)
      Object.send(:remove_const, :SERVICES)
    end
  end

  def run_script(input, env = {})
    # Build command with proper quoting for input
    cmd = "ruby #{script_path} #{input.empty? ? "''" : "'#{input}'"}"
    
    # Run command with environment variables
    stdout, stderr, status = Open3.capture3(env, cmd)
    
    # Debug output if something goes wrong
    if stdout.empty? || !status.success?
      puts "Debug: Command: #{cmd}"
      puts "Debug: Environment: #{env}"
      puts "Debug: Status: #{status.exitstatus}"
      puts "Debug: STDERR: #{stderr}"
      puts "Debug: STDOUT: #{stdout}"
    end

    [JSON.parse(stdout), stderr, status]
  rescue JSON::ParserError => e
    puts "Debug: Failed to parse JSON output: '#{stdout}'"
    raise e
  end

  describe '.load_services' do
    before do
      ENV['SERVICES_JSON'] = nil
    end

    it 'uses default services when SERVICES_JSON is not set' do
      expect(ScriptFilter.load_services).to eq(default_services)
    end

    it 'uses custom services when valid SERVICES_JSON is provided' do
      custom_services = [
        { name: "Custom", code: "cu", urlTemplate: "https://custom.com/?q=${prompt}" }
      ]
      ENV['SERVICES_JSON'] = custom_services.to_json
      expect(ScriptFilter.load_services).to eq(custom_services)
    end

    it 'falls back to default services when invalid JSON is provided' do
      ENV['SERVICES_JSON'] = 'invalid json'
      expect(ScriptFilter.load_services).to eq(default_services)
    end
  end

  describe '#process_input' do
    it 'shows all services when input is empty' do
      result = filter.process_input('')
      expect(result['items'].length).to eq(default_services.length)
      expect(result['items'].first).to include(
        'title' => "#{default_services.first[:name]} (#{default_services.first[:code]})",
        'valid' => false
      )
    end

    it 'shows error for unknown service code' do
      result = filter.process_input('unknown')
      expect(result['items'].first['title']).to eq('Unknown Service')
    end

    it 'prompts for input when only service code is provided' do
      result = filter.process_input('co')
      expect(result['items'].first['title']).to match(/Type your prompt for Copilot/)
    end

    it 'generates correct URL when service and prompt are provided' do
      result = filter.process_input('co test prompt')
      expect(result['items'].first).to include(
        'title' => 'Send to Copilot',
        'subtitle' => 'test prompt',
        'arg' => 'https://github.com/copilot?prompt=test%20prompt',
        'valid' => true
      )
    end

    it 'properly encodes special characters in prompt' do
      result = filter.process_input('co test & prompt?')
      expect(result['items'].first['arg']).to include('test%20%26%20prompt%3F')
    end
  end

  describe 'custom services' do
    let(:custom_services) do
      [{
        name: 'CustomAI',
        code: 'cai',
        urlTemplate: 'https://custom.ai/chat?q=${prompt}'
      }]
    end
    let(:filter) { ScriptFilter.new(custom_services) }

    it 'uses custom services when provided' do
      result = filter.process_input('')
      items = result['items']
      expect(items.size).to eq(1)
      expect(items.first['title']).to eq('CustomAI (cai)')
    end

    it 'builds correct URL for custom service' do
      result = filter.process_input('cai test query')
      items = result['items']
      expect(items.first).to include(
        'title' => 'Send to CustomAI',
        'subtitle' => 'test query',
        'arg' => 'https://custom.ai/chat?q=test%20query'
      )
    end
  end

  describe 'URL encoding' do
    it 'properly encodes special characters' do
      json_output, stderr, status = run_script('co test & query + spaces')
      
      expect(status).to be_success
      expect(stderr).to be_empty
      
      item = json_output['items'].first
      expect(item['arg']).to include('test%20%26%20query%20%2B%20spaces')
    end
  end
end