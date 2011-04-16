shared_examples_for 'SpecHelper examples' do
  after do
    EM.reactor_running?.should == false
    AMQP.connection.should be_nil
  end

  it "should not require a call to done when #em/#amqp is not used" do
    1.should == 1
  end

  it "should properly work" do
    amqp { done }
  end

  it "should have timers" do
    start = Time.now
    amqp do
      EM.add_timer(0.5) {
        (Time.now-start).should be_within(0.1).of(0.5)
        done
      }
    end
  end

  it 'should have deferrables' do
    amqp do
      defr = EM::DefaultDeferrable.new
      defr.timeout(0.5)
      defr.errback {
        done
      }
    end
  end

  it "should run AMQP.start loop with options given to #amqp" do
    amqp(:vhost => '/', :user => 'guest') do
      AMQP.connection.should be_connected
      done
    end
  end

  it "should properly close AMQP connection if block completes normally" do
    amqp do
      AMQP.connection.should be_connected
      done
    end
    AMQP.connection.should be_nil
  end

  # TODO: remove dependency on (possibly long) DNS lookup
  it "should gracefully exit if no AMQP connection was made" do
    # EventMachine::ConnectionError isn't available in JRuby, where
    # NativeException: java.nio.channels.UnresolvedAddressException is raised instead
    connection_exception = defined?(EventMachine::ConnectionError) ? EventMachine::ConnectionError : NativeException
    expect {
      amqp(:host => '192.168.0.256') do
        AMQP.connection.should be_nil
        done
      end
    }.to raise_error(connection_exception)
    AMQP.connection.should be_nil
  end

  it_should_behave_like 'done examples'

  it_should_behave_like 'timeout examples'
end

shared_examples_for 'done examples' do

  it 'should yield to block given to done (when amqp is used)' do
    amqp do
      done { @block_called = true; EM.reactor_running?.should == true }
    end
    @block_called.should == true
  end

  it 'should yield to block given to done (when em is used)' do
    em do
      done { @block_called = true; EM.reactor_running?.should == true }
    end
    @block_called.should == true
  end

  it 'should have delayed done (when amqp is used)' do
    start = Time.now
    amqp do
      done(0.2) { @block_called = true; EM.reactor_running?.should == true }
    end
    @block_called.should == true
    (Time.now-start).should be_within(0.1).of(0.2)
  end

  it 'should have delayed done (when em is used)' do
    start = Time.now
    em do
      done(0.2) { @block_called = true; EM.reactor_running?.should == true }
    end
    @block_called.should == true
    (Time.now-start).should be_within(0.1).of(0.2)
  end
end

shared_examples_for 'timeout examples' do
  before { @start = Time.now }

  it 'should timeout before reaching done because of default spec timeout' do
    expect { amqp { EM.add_timer(2) { done } } }.
        to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
    (Time.now-@start).should be_within(0.1).of(1.0)
  end

  it 'should timeout before reaching done because of explicit in-loop timeout' do
    expect {
      amqp do
        timeout(0.2)
        EM.add_timer(0.5) { done }
      end
    }.to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
    (Time.now-@start).should be_within(0.1).of(0.2)
  end

  specify "spec timeout given in amqp options has higher priority than default" do
    expect { amqp(:spec_timeout => 0.2) {} }.
        to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
    (Time.now-@start).should be_within(0.3).of(0.2)
  end

  specify "but timeout call inside amqp loop has even higher priority" do
    expect { amqp(:spec_timeout => 4.5) { timeout(0.2) } }.
        to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
    (Time.now-@start).should be_within(0.2).of(0.2)
  end

  specify "AMQP connection should not leak between examples" do
    AMQP.connection.should be_nil
  end

  context 'embedded context can set up separate defaults' do
    default_timeout 0.2 # Can be used to set default :spec_timeout for all evented specs

    specify 'default timeout should be 0.2' do
      expect { em { EM.add_timer(2) { done } } }.to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
      (Time.now-@start).should be_within(0.1).of(0.2)
    end

    context 'deeply embedded context can set up separate defaults' do
      default_timeout 0.5

      specify 'default timeout should be 0.5' do
        expect { amqp { EM.add_timer(2) { done } } }.to raise_error EventedSpec::SpecHelper::SpecTimeoutExceededError
        (Time.now-@start).should be_within(0.1).of(0.5)
      end
    end
  end
end

shared_examples_for 'Spec examples' do
  after(:each) do
    # By this time, EM loop is stopped, either by timeout, or by exception
    EM.reactor_running?.should == false
  end

  it 'should work' do
    done
  end

  it 'should have timers' do
    start = Time.now

    EM.add_timer(0.2) {
      (Time.now-start).should be_within(0.1).of(0.2)
      done
    }
  end

  it 'should have periodic timers' do
    num = 0
    start = Time.now

    timer = EM.add_periodic_timer(0.2) {
      if (num += 1) == 2
        (Time.now-start).should be_within(0.1).of(0.5)
        EM.cancel_timer timer
        done
      end
    }
  end

  it 'should have deferrables' do
    defr = EM::DefaultDeferrable.new
    defr.timeout(0.2)
    defr.errback {
      done
    }
  end
end