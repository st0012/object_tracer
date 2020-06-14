require 'rspec/expectations'

RSpec::Matchers.define :write_to_file do |filepath, expected_content|
  file_exists = File.exists?(filepath)

  match do |actual|
    actual.call

    if file_exists
      actual_content = File.read(filepath)

      case expected_content
      when String
        actual_content == expected_content
      when Regexp
        actual_content.match?(expected_content)
      end
    else
      false
    end
  end

  failure_message do |actual|
    if !file_exists
      "expect file '#{filepath}' to exist"
    else
      "expect file to contain:\n#{expected_content}\ngot:\n#{File.read(filepath)} instead."
    end
  end

  def supports_block_expectations?
    true
  end
end
