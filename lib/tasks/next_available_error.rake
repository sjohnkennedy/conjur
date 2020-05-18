require 'util/error_code'

namespace :error_code do
  task :next do
    error_code = Util::ErrorCode.new('./app/domain/errors.rb')
    error_code.next_available
  end
end
