RSpec.shared_examples "stoppable" do
  it "stopps tapping when stop! is called" do
    device.send(subject, target)

    trigger_action.call(target)

    expect(device.calls.count).to eq(1)

    device.stop!

    trigger_action.call(target)

    expect(device.calls.count).to eq(1)
  end

  it "stops tapping once fulfill stop_when condition" do
    device.stop_when do |payload|
      device.calls.count == 10
    end

    device.send(subject, target)

    100.times do
      trigger_action.call(target)
    end

    expect(device.calls.count).to eq(10)
  end
end
