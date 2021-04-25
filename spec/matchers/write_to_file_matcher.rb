require 'rspec/expectations'

RSpec::Matchers.define :write_to_file do |filepath, expected_content|
  match do |actual|
    actual.call
    file_exists = File.exists?(filepath)

    if file_exists
      @actual_content = File.read(filepath)

      case expected_content
      when String
        @actual_content == expected_content
      when Regexp
        @actual_content.match?(expected_content)
      end
    else
      false
    end
  end

  failure_message do |actual|
    "expect file to contain:\n#{expected_content}\ngot:\n#{@actual_content} instead."
  end

  def supports_block_expectations?
    true
  end
end
