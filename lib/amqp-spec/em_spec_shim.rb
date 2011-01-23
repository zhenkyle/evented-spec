# Monkey patching EM to provide drop-in experience for legacy EM-Spec based examples.
# Remember: monkey patching is dangerous, confusing and will come to haunt you.
module EventMachine
  Spec = AMQP::EMSpec
  SpecHelper = AMQP::SpecHelper
end