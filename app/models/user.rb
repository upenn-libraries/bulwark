class User < ActiveRecord::Base
  has_many :bulk_imports

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end

  # Connects this user object to Blacklight Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  serialize :job_activity, Hash

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def update_jobs(process)
    self.job_activity.keys.each do |key|
      if self.job_activity[key][:process] == process && ActiveJobStatus::JobStatus.get_status(job_id: key).nil?
        self.job_activity.delete(key)
      end
    end
    self.save
  end
end
