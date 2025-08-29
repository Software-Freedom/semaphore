require "sidekiq/api"

class Evolution::RetryMessageJob < ApplicationJob
  queue_as :default

  sidekiq_options(
    lock: :until_executed,
    lock_ttl: 10.seconds,
    unique_args: ->(args) { args[0] }
  )

  def perform(lock_key, id)
    message = Chatwoot::Message.find_by_id(id)

    return unless message
    return if message.delivery?
    
    message.update(retried: true)
    Evolution::SendMessageJob.perform_now(lock_key, id)
  end

  class << self
    def remove_scheduled(lock_key, id)
      scheduled = Sidekiq::ScheduledSet.new
      scheduled.each do |job|
        job_klass = job.args.first["job_class"]
        job_args = job.args.first["arguments"]

        if job_klass == name && job_args == [lock_key, id]
          job.delete
        end
      end
    end
  end
end
