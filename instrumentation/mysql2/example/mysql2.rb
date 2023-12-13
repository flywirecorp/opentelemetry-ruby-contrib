# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

require "net/http"

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Net::HTTP'
  c.use 'OpenTelemetry::Instrumentation::Mysql2'
end

client = Mysql2::Client.new(
  host: ENV.fetch('TEST_MYSQL_HOST') { '127.0.0.1' },
  port: ENV.fetch('TEST_MYSQL_PORT') { '3306' },
  database: ENV.fetch('TEST_MYSQL_DB') { 'mysql' },
  username: ENV.fetch('TEST_MYSQL_USER') { 'root' },
  password: ENV.fetch('TEST_MYSQL_PASSWORD') { 'root' }
)

tracer = OpenTelemetry.tracer_provider.tracer("untraced_test")

tracer.in_span("our_first_span") do |span|
  OpenTelemetry::Common::Utilities.untraced do
    client.query("SELECT 1")
  end

  span.set_attribute("foo", "bar")
end

tracer.in_span("our_second_span") do |span|
  OpenTelemetry::Common::Utilities.untraced do
    Net::HTTP.get(URI('https://www.google.com'))
  end

  span.set_attribute("foo", "bar")
end
